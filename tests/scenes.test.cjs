const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const {spawnSync} = require('node:child_process');
const root = path.join(__dirname, '..');

function load(relative, globals = {}) {
    const context = vm.createContext(globals);
    const source = fs.readFileSync(path.join(root, relative), 'utf8').replace(/^\.import.*\n/gm, '');
    vm.runInContext(source, context);
    return context;
}

const pages = load('src/utils/ScenePages.js');
const color = load('src/utils/Color.js', {console});
const palette = load('src/utils/ScenePalette.js', {ColorUtils: color});
const plain = value => JSON.parse(JSON.stringify(value));

test('every page reserves eight slots without losing or duplicating scenes', () => {
    for (const count of [0, 1, 5, 8, 9, 16, 17]) {
        const scenes = Array.from({length: count}, (_, id) => ({id}));
        const actual = [];
        for (let page = 0; page < pages.pageCount(scenes); page++) {
            const slots = plain(pages.slots(scenes, page));
            assert.equal(slots.length, 8);
            actual.push(...slots.filter(Boolean));
        }
        assert.deepEqual(actual, scenes);
    }
});

test('pagination clamps stale and negative page indexes after a scene collection shrinks', () => {
    const scenes = [{id: 'one'}];
    assert.equal(plain(pages.slots(scenes, 8))[0].id, 'one');
    assert.equal(plain(pages.slots(scenes, -1))[0].id, 'one');
    assert.deepEqual(plain(pages.slots([], 8)), Array(8).fill(null));
});

test('scene previews deduplicate colours and distinguish warm and cool whites', () => {
    assert.equal(palette.colors({preview: [{temperature: 250}, {temperature: 250}]}).length, 1);
    assert.equal(palette.colors({preview: [{xy: {x: 0, y: 0}}, {temperature: 0}]}).length, 0);
    assert.equal(palette.colors({}).length, 0);
    const warm = palette.temperatureColor(500);
    const cool = palette.temperatureColor(156);
    assert.match(warm, /^#[0-9a-f]{6}$/i);
    assert.match(cool, /^#[0-9a-f]{6}$/i);
    assert.ok(parseInt(warm.slice(5, 7), 16) < parseInt(cool.slice(5, 7), 16));
    const colors = palette.colors({preview: [156, 200, 250, 350, 500].map(temperature => ({temperature}))});
    assert.equal(colors.length, 3);
});

const maps = fs.readFileSync(path.join(root, 'src/Service/JqMaps.qml'), 'utf8');
function parseMap(name, value) {
    const expression = maps.match(new RegExp('property string ' + name + ': `([^`]+)`'))[1];
    const result = spawnSync('jq', [expression], {input: JSON.stringify(value) + '\n', encoding: 'utf8', timeout: 5000});
    assert.equal(result.status, 0, result.stderr);
    return JSON.parse(result.stdout);
}

test('OpenHue singleton and array responses produce the same room and scene records', () => {
    const room = {
        Id: 'room', Name: 'Bedroom',
        GroupedLight: {HueData: {on: {on: true}, dimming: {brightness: 40}}},
        Devices: [{Light: {Id: 'lamp', Name: 'Desk'}}],
        Scenes: [{Id: 'scene', Name: 'Reading', HueData: {
            status: {active: 'static'},
            palette: {color_temperature: [{color_temperature: {mirek: 346}}]},
            actions: [{action: {color: {xy: {x: 0.5, y: 0.4}}}}]
        }}]
    };
    const single = parseMap('rooms', room);
    assert.deepEqual(single, parseMap('rooms', [room]));
    assert.equal(single[0].scenes.length, 1);
    assert.equal(single[0].scenes[0].preview.length, 2);
    assert.equal(palette.colors(single[0].scenes[0]).length, 2);
    assert.deepEqual(parseMap('rooms', []), []);
});

test('OpenHue singleton and array responses produce the same lamp records', () => {
    const lamp = {Id: 'lamp', Name: 'Desk', HueData: {
        on: {on: true}, dimming: {brightness: 40, min_dim_level: 1},
        color: null, color_temperature: null
    }, Parent: {Parent: {Id: 'room', Name: 'Bedroom'}}};
    const single = parseMap('lights', lamp);
    assert.deepEqual(single, parseMap('lights', [lamp]));
    assert.equal(single[0].dimming.minDimming, 1);
    assert.deepEqual(parseMap('lights', []), []);
});

test('applying lamp data preserves percentage units and defaults a missing minimum to zero', () => {
    const source = fs.readFileSync(path.join(root, 'src/Service/Service.qml'), 'utf8');
    const body = source.match(/function applyLightData\(target, data\) \{([\s\S]*?)\n    \}/)[1];
    const context = vm.createContext();
    vm.runInContext('function apply(target, data) {' + body + '\n}', context);
    const target = {};
    const data = {dimming: {dimming: 30, minDimming: 1}, color: null, temperature: null};
    context.apply(target, data);
    assert.equal(target.dimming, 30);
    assert.equal(target.minDimming, 1);
    delete data.dimming.minDimming;
    context.apply(target, data);
    assert.equal(target.minDimming, 0);
});
