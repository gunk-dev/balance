import { test, expect } from "@playwright/test";

test.describe("Metric recording", () => {
  test("records a value and persists across reload", async ({ page }) => {
    await page.goto("/");

    // Wait for app to load
    const moodSlider = page.getByTestId("metric-m1");
    await expect(moodSlider).toBeVisible();

    // Click the 3rd step (index 2) on the Mood metric
    await moodSlider.getByTestId("step-2").click();

    // Verify the step shows as selected (active step has bg-mint class with full size)
    const activeStep = moodSlider.getByTestId("step-2").locator("div");
    await expect(activeStep).toHaveClass(/bg-mint rounded-full shadow/);

    // Verify "Recorded" text appears
    await expect(moodSlider.getByText("Recorded")).toBeVisible();

    await page.screenshot({
      path: "test-results/metric-recorded.png",
      fullPage: true,
    });

    // Reload and verify persistence
    await page.reload();
    await expect(moodSlider).toBeVisible();

    // Value should persist from IndexedDB
    await expect(moodSlider.getByText("Recorded")).toBeVisible();
    const persistedStep = moodSlider.getByTestId("step-2").locator("div");
    await expect(persistedStep).toHaveClass(/bg-mint rounded-full shadow/);

    await page.screenshot({
      path: "test-results/metric-persisted.png",
      fullPage: true,
    });
  });
});
