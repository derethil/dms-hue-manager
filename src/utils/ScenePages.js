function pageCount(scenes) {
    return Math.max(1, Math.ceil(scenes.length / 8));
}

function slots(scenes, pageIndex) {
    const page = Math.max(0, Math.min(pageCount(scenes) - 1, Math.floor(pageIndex) || 0));
    const result = scenes.slice(page * 8, page * 8 + 8);
    while (result.length < 8)
        result.push(null);
    return result;
}
