import { test, expect } from "@playwright/test";

test.describe("PWA", () => {
  test("serves valid web manifest", async ({ page }) => {
    await page.goto("/");

    const response = await page.request.get("/manifest.webmanifest");
    expect(response.ok()).toBe(true);

    const manifest = await response.json();
    expect(manifest.name).toBe("Balance");
  });

  test("has theme-color meta tag", async ({ page }) => {
    await page.goto("/");

    const themeColor = page.locator('meta[name="theme-color"]');
    await expect(themeColor).toBeAttached();

    await page.screenshot({
      path: "test-results/pwa-meta.png",
      fullPage: true,
    });
  });
});
