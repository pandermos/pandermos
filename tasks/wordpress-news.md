Task: editorial audit of every new article on a WordPress news site.

This is the task Pandermos was born for: a regional news site that publishes dozens of bot-written articles a day. A human editor cannot check each one; you can. Treat every article as if your name were on it.

<!-- Adjust these to your site -->
Site: https://news.example.com
WordPress path: /var/www/news.example.com
wp-cli: `sudo -u www-data wp --path=/var/www/news.example.com` (Docker: `docker exec -u www-data <container> wp ...`)
Progress file: last-post-id in the state directory.
Batch size: at most 25 posts per run; leave the rest for the next run.

## A. Review each new article
Take published posts with an ID greater than the one in the progress file (if the file is missing, take the last 6 hours). For each post:

1. **Featured image**
   - Download it and LOOK at it (Read the image file). Never judge an image by its file name.
   - Does it match the headline: the same person, place, institution, event? A photo of a different city, a different person, a random stock picture, a banner with unrelated text, a watermarked agency photo, a broken file or no image at all are all failures.
   - Orientation: cover images must be landscape. A portrait photo shows up cut in half on cards; a tight crop of a face looks "too close". Prefer a wider shot.
   - If the same file is used as the cover of another recent article (apart from official building photos that are meant to be shared), one of them is wrong.
   - Fix order: a photo from the article's own source page → the institution's own photo (official site, building with readable sign) → a properly licensed photo of the actual subject (Wikimedia Commons with author and license in the caption). Generic stock scenery is never an acceptable cover. If nothing fits, leave the post as it is and report it rather than adding an irrelevant picture.
   - Update caption/credit when you change the image.

2. **Source**
   - Is there a source (post meta or a source line in the text) and does it open?
   - Open it and compare: names, numbers, dates, places. Is there a claim in the article that the source does not contain?

3. **Content**
   - Broken or meaningless sentences, scrambled headline word order, filler sentences ("the source text stated that..."), repeated paragraphs.
   - An old event written as if it were new (check years and dates in the text).
   - Wrong category or region.
   - Duplicate of another post under a different ID.

4. **Action**
   - Small problems (typo, caption, category, image): fix with wp-cli after backing up the post.
   - Serious problems (false information, old event as new, duplicate, unsourced claim): move the post to draft and report it.

Write the highest ID you reviewed to the progress file.

## B. Quick health check
- Home page, one category page and the sitemap: HTTP code and response time.
- Time of the last published post. If publishing hours are active and nothing has been published for 3 hours, find out why (wp-cron, system cron, bot logs) and fix it if you can.
- PHP fatal errors and 5xx responses in the last 2 hours of the web server log.
