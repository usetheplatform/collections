describe("Collections - Desktop", () => {
    beforeAll(async () => {
        await page.goto("localhost:1234");
    });

    it("should find a collections node in the dom", async () => {
        let result = await page.$eval(".collections", el => el);
        expect(result).toBeTruthy();
    });

    it("should match the sreenshot", () => {
        throw new Error("Not implemented!");
    });

    // Перехватить запросы и проверить что при посещении отправляется запрос к апи
    it("should start loading photos from the api right from the start", () => {
        throw new Error("Not implemented!");
    });

    // При загрузке фотографий должен отрендарить 30 фотокарточек на странице
    it("shold render photos in the collection", () => {
        throw new Error("Not implemented!");
    });

    it("should start loading additional photos, when user clicks on load more button", () => {
        throw new Error("Not implemented!");
    });
});

// TODO: Setup tests for mobile
// describe("Collections - Mobile", () => {
//     beforeAll(async () => {
//         await page.goto("localhost:1234");
//     });

//     it("should find a collections node in the dom", async () => {
//         let result = await page.$eval(".collections", el => el);
//         expect(result).toBeTruthy();
//     });

//      it("should match the sreenshot", () => {
//          throw new Error("Not implemented!");
//      });

//     // Перехватить запросы и проверить что при посещении отправляется запрос к апи
//     it("should start loading photos from the api right from the start", () => {
//         throw new Error("Not implemented!");
//     });

//     // При загрузке фотографий должен отрендарить 30 фотокарточек на странице
//     it("shold render photos in the collection", () => {
//         throw new Error("Not implemented!");
//     });

//     it("should start loading additional photos, when user clicks on load more button", () => {
//         throw new Error("Not implemented!");
//     });
// });
