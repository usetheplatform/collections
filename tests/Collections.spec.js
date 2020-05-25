const { photos } = require("./fixtures/photos");

describe("Collections - Desktop", () => {
    it("should find a collections node in the dom", async () => {
        await page.goto("localhost:1234");
        let result = await page.$eval(".collections", el => el);
        expect(result).toBeTruthy();
    });

    // TODO: Not supported https://github.com/microsoft/playwright/issues/1774 :C
    // it.only("should match the sreenshot", async () => {
    //     // await page.on("response", async (response) => {
    //     //     console.log(response.url());
    //     //     try {
    //     //         console.log(response.headers())
    //     //         if (response.headers()["Content Type"] === "application/json") {
    //     //             const json = await response.json();
    //     //             console.log(json);
    //     //         }

    //     //     } catch (error) {
    //     //         console.log(error);
    //     //     }


    //     // });
    //     await page.goto("localhost:1234");
    //     await page.route(/photos/, route => route.fulfill({
    //         status: 200,
    //         contentType: "application/json",
    //         body: JSON.stringify(photos),
    //     }));

    //     await page.waitForResponse(/photos/);
    //     await page.waitForSelector("[data-image-id]");

    //     await page.screenshot({ path: "./screenshots/collections_desktop.png" });
    // });

    it("should start loading photos from the api right from the start", async () => {
        await page.goto("localhost:1234");

        let response = await page.waitForResponse(/photos/);
        let body = await response.json();
        let headers = response.headers();

        expect(headers).toHaveProperty('x-total');
        expect(headers).toHaveProperty('x-per-page');
        expect(body).toHaveLength(30);
    });

    it("shold render photos in the collection", async () => {
        await page.goto("localhost:1234");

        let images = await page.$$eval("[data-image-id]", el => el);
        expect(images).toHaveLength(0);

        await page.waitForResponse(/photos/);
        await page.waitForSelector("[data-image-id]");
        images = await page.$$eval("[data-image-id]", el => el);

        expect(images).toHaveLength(30);
    });

    it("should start loading additional photos, when user clicks on load more button", async () => {
        await page.goto("localhost:1234");

        await page.waitForResponse(/photos/);

        await page.click("[data-button='load-more']");

        let response = await page.waitForResponse(/photos/);

        await page.waitForSelector("[data-image-id]");

        let images = await page.$$eval("[data-image-id]", el => el);
        expect(response.url()).toContain("page=2");
        expect(images).toHaveLength(60);
    });

    it.skip("should start loading additional photos, when user scrolls down of the page", async () => {
        let onIntersectedMock = jest.fn();
        await page.goto("localhost:1234");

        await page.waitForResponse(/photos/);
        let scrollListener = await page.$("[data-test-id='scroll-listener']");
        await scrollListener.evaluate(el => el.addEventListener("onIntersected", () => onIntersectedMock()));

        await page.on("request", request => console.log(request.url()));
        await page.evaluate(() => {
            window.scrollBy(0, window.innerHeight);
        });

        let response = await page.waitForResponse(/photos/);

        await page.waitForSelector("[data-image-id]");
        let images = await page.$$eval("[data-image-id]", el => el);

        expect(onIntersectedMock).toHaveBeenCalled();
        expect(response.url()).toContain("page=2");
        expect(images).toHaveLength(60);

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
