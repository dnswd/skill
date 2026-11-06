---
description: Read deepwiki.com URLs.
---

# DeepWiki

deepwiki.com URLs return HTTP 429 to standard `read` calls due to a security checkpoint. Bypassing it requires a real browser via the `eval` tool.

1. **Extract text** by running this `eval` snippet:
   ```javascript
   const tab = await browser.open({ name: "wiki", url: "TARGET_URL" });
   const text = await tab.run(async ({ page }) => {
     await new Promise(r => setTimeout(r, 5000));
     return await page.evaluate(() => document.body.innerText);
   });
   await tab.close();
   await Bun.write("deepwiki-content.txt", text);
   ```

2. **Read the result**: Use the `read` tool on `deepwiki-content.txt` to safely load the full article without console truncation.

3. **Verify completion**: The article text is fully loaded into context.
