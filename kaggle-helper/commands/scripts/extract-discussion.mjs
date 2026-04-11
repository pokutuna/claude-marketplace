// Extract Kaggle Discussion page to Markdown
// Usage: playwright-cli run-code --filename=extract-discussion.mjs

async (page) => {
  await page.addScriptTag({ url: "https://unpkg.com/turndown/dist/turndown.js" })

  const result = await page.evaluate(() => {
    const td = new TurndownService({ headingStyle: "atx", codeBlockStyle: "fenced" })

    function findBodyDiv(container) {
      const divs = [...container.querySelectorAll("div")]
      return divs.reverse().find(d => {
        const hasContent = d.querySelector(":scope > p, :scope > pre, :scope > ul, :scope > ol, :scope > blockquote, :scope > h1, :scope > h2, :scope > h3, :scope > h4")
        if (!hasContent) return false
        const t = d.textContent.trim()
        return !t.startsWith("Posted") && !t.includes("arrow_drop_up")
      })
    }

    function convertBody(container) {
      const el = findBodyDiv(container)
      if (!el) return ""
      const clone = el.cloneNode(true)
      clone.querySelectorAll("button").forEach(e => e.remove())
      clone.querySelectorAll("span").forEach(s => {
        if (s.textContent.trim() === "content_copy") s.remove()
      })
      return td.turndown(clone.innerHTML)
    }

    function parseMeta(el) {
      const aLink = el.querySelector('a[aria-label$="\'s profile"]')
      const authorId = aLink?.getAttribute("href")?.replace(/^\//, "") || ""
      const votes = el.querySelector('button[aria-label*="votes"]')?.textContent?.trim() || "0"
      const rank = el.textContent.match(/(\d+)(?:st|nd|rd|th) in this Competition/)?.[1] || ""
      return { authorId, votes, rank }
    }

    function fmtMeta(m) {
      let s = `@${m.authorId}`
      if (m.rank) s += ` (${m.rank}th)`
      if (m.votes !== "0") s += ` [${m.votes} votes]`
      return s
    }

    // Flatten all comments with numbering and reply-to references
    function flattenComments(els) {
      const result = []
      let num = 0

      function visit(el, parentNum) {
        num++
        const meta = parseMeta(el)
        const clone = el.cloneNode(true)
        clone.querySelectorAll('[data-testid="discussions-comment"]').forEach(c => c.remove())
        const body = convertBody(clone)
        const myNum = num
        result.push({ ...meta, body, num: myNum, parentNum })

        const replies = [...el.querySelectorAll('[data-testid="discussions-comment"]')]
          .filter(c => c.parentElement.closest('[data-testid="discussions-comment"]') === el)
        for (const r of replies) visit(r, myNum)
      }

      for (const el of els) visit(el, null)
      return result
    }

    function formatComment(c) {
      let header = `### #${c.num} ${fmtMeta(c)}`
      if (c.parentNum) header += ` → #${c.parentNum}`
      let md = header + "\n\n"
      if (c.body) md += c.body + "\n\n"
      return md
    }

    // --- Topic ---
    const header = document.querySelector('[data-testid="discussions-topic-header"]')
    if (!header) return JSON.stringify("Error: No discussion found on this page.")

    const title = header.querySelector("h3")?.textContent?.trim() ||
      document.title.replace(/\s*\|\s*Kaggle$/, "").trim()
    const meta = parseMeta(header)
    const topicBody = convertBody(header)

    // --- Comments ---
    const container = document.querySelector('[data-testid="discussion-detail-render-tid"]')
    const topLevel = container
      ? [...container.querySelectorAll('[data-testid="discussions-comment"]')]
          .filter(c => !c.parentElement.closest('[data-testid="discussions-comment"]'))
      : []

    // --- Output ---
    let output = `# ${title}\n\n`
    output += `**${fmtMeta(meta)}**\n`
    output += `URL: ${window.location.href}\n\n`
    output += "---\n\n"
    output += topicBody + "\n\n"

    if (topLevel.length > 0) {
      const comments = flattenComments(topLevel)
      output += "---\n\n"
      output += `## Comments (${comments.length})\n\n`
      for (const c of comments) {
        output += formatComment(c)
      }
    }

    return JSON.stringify(output)
  })

  return result
}
