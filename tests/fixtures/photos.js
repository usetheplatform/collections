const tiles = {
    s: require("./images/tile_s.jpg"),
    m: require("./images/tile_m.jpg"),
    l: require("./images/tile_l.jpg"),
    xl: require("./images/tile_xl.jpg")
};

function getTile(index) {
    let position = index % 4;
    switch (position) {
        case 0: {
            return {
                url: tiles.s,
                width: 125,
                height: 250,
            };
        }
        case 1: {
            return {
                url: tiles.m,
                width: 189,
                height: 250,
            };
        }
        case 2: {
            return {
                url: tiles.l,
                width: 269,
                height: 250,
            };
        }
        case 3: {
            return {
                url: tiles.xl,
                width: 414,
                height: 250,
            };
        }
        default: {
            return {
                url: tiles.m,
                width: 189,
                height: 250,
            };
        }
    }
}

const photos = new Array(30).fill(undefined, 0, 30).map((val, index) => {
    let tile = getTile(index);

    return {
        id: index.toString(),
        width: tile.width,
        height: tile.height,
        color: "#fc0",
        description: "",
        user: {
            id: "1",
            username: "johndoe",
            name: "John Doe"
        },
        urls: {
            small: tile.url,
            raw: tile.url,
        }
    };
});

module.exports = {
    photos,
}
