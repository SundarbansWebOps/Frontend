import { test, expect } from '@playwright/test';

test.describe('Landing page features and Google Doc integration', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/#/', { waitUntil: 'load' });
  });

  test('renders UHC team card social media buttons with valid external links', async ({ page }) => {
    const councilSection = page.locator('#teams');
    await expect(councilSection).toBeVisible();

    // Verify Divya Prakash LinkedIn button
    const divyaCard = councilSection.locator('.council-card', { hasText: 'Divya Prakash' });
    await expect(divyaCard).toBeVisible();
    const divyaLinkedIn = divyaCard.locator('a[aria-label="Divya Prakash on LinkedIn"]');
    await expect(divyaLinkedIn).toBeVisible();
    await expect(divyaLinkedIn).toHaveAttribute(
      'href',
      'https://in.linkedin.com/in/divya-prakash-5b564b273'
    );
    await expect(divyaLinkedIn).toHaveAttribute('target', '_blank');

    // Verify Anuraj Jit Saikia LinkedIn and X buttons
    const anurajCard = councilSection.locator('.council-card', { hasText: 'Anuraj Jit Saikia' });
    await expect(anurajCard).toBeVisible();
    const anurajLinkedIn = anurajCard.locator('a[aria-label="Anuraj Jit Saikia on LinkedIn"]');
    await expect(anurajLinkedIn).toBeVisible();
    await expect(anurajLinkedIn).toHaveAttribute(
      'href',
      'https://www.linkedin.com/in/anurajjitsaikia/'
    );
    await expect(anurajLinkedIn).toHaveAttribute('target', '_blank');

    const anurajX = anurajCard.locator('a[aria-label="Anuraj Jit Saikia on X"]');
    await expect(anurajX).toBeVisible();
    await expect(anurajX).toHaveAttribute('href', 'https://x.com/raja_saikia_');
    await expect(anurajX).toHaveAttribute('target', '_blank');
  });

  test('renders House Crew Map with all 4 operational tiers', async ({ page }) => {
    const crewSection = page.locator('.crew-structure-section');
    await expect(crewSection).toBeVisible();

    const helm = crewSection.locator('.crew-card', { hasText: 'At the helm' });
    const oars = crewSection.locator('.crew-card', { hasText: 'At the oars' });
    const drum = crewSection.locator('.crew-card', { hasText: 'On the drum' });
    const hull = crewSection.locator('.crew-card', { hasText: 'In the hull' });

    await expect(helm).toBeVisible();
    await expect(oars).toBeVisible();
    await expect(drum).toBeVisible();
    await expect(hull).toBeVisible();

    await expect(helm).toContainText('Upper House Council');
    await expect(oars).toContainText('Lower House Council');
    await expect(drum).toContainText('Communities');
    await expect(hull).toContainText('Technical & Creative Crew');
  });

  test('displays official Sep 2026 Student Grading Document and OPPE SCT guide', async ({
    page,
  }) => {
    // 1. Term Academic Brief Card
    const termBrief = page.locator('.term-brief-card');
    await expect(termBrief).toBeVisible();
    await expect(termBrief).toContainText('Sep 2026 Term');
    await expect(termBrief).toContainText('Quiz 1 (In Person)');
    await expect(termBrief).toContainText('15 Nov 2026');
    await expect(termBrief).toContainText('OPPE 1 (Online Proctored)');
    await expect(termBrief).toContainText('22 Nov 2026');
    await expect(termBrief).toContainText('End Term Exam');
    await expect(termBrief).toContainText('10 Jan 2027');

    // 2. Official Google Doc card
    const gradingDocCard = page.locator('.utility-card', { hasText: 'Sep 2026 Grading Document' });
    await expect(gradingDocCard).toBeVisible();
    const docLink = gradingDocCard.locator('a');
    await expect(docLink).toHaveAttribute(
      'href',
      'https://docs.google.com/document/d/e/2PACX-1vT_FeqnTq0Br4sUaN7OYAmj1B9MwjchyTEed1Bh5FkZvi5NyIMeAvvkuttostVsJBPjZcs3SjjEfiho/pub'
    );
    await expect(docLink).toHaveAttribute('target', '_blank');

    // 3. OPPE SCT Setup Guide card
    const sctCard = page.locator('.utility-card', { hasText: 'OPPE SCT Setup Guide' });
    await expect(sctCard).toBeVisible();
    const sctLink = sctCard.locator('a');
    await expect(sctLink).toHaveAttribute(
      'href',
      'https://docs.google.com/document/d/e/2PACX-1vS4Hhh4MsKD2WL8_D26Vw2WJKw0CBtPihZyKrnEM_kefRXm_O75GqTcJA6lR0X_xCiVL5gUi5y6_bjw/pub'
    );
    await expect(sctLink).toHaveAttribute('target', '_blank');
  });
});
