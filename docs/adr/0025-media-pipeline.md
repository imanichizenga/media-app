# 0025. Media pipeline

Status: accepted, 2026-11-24

## Context
Reporters upload gigabytes over mobile connections, and every file is untrusted.

## Decision
- **Upload:** the browser sends parts straight to the bucket with presigned URLs whose length is signed. The API signs, lists what arrived, and checks the total before completing. An interrupted upload resumes from the parts that arrived, even in another tab.
- **Scan before anything opens the file.** In AWS, GuardDuty Malware Protection tags the object, and the bucket policy refuses to hand out an original without `NO_THREATS_FOUND`, even to our own code; only the scanner may write that tag. A pending verdict costs one small request per retry. Anything but "clean" rejects the file. Locally: ClamAV, or a scanner that knows one test signature. No scanner, no processing.
- **Images:** libvips, with type and pixel count checked from the bytes before decoding. All metadata is removed. AVIF, WebP and JPEG at five widths, three crops around a focal point, blurhash and dominant colour. Moving the focal point makes new crops while the old ones stay in use.
- **Video:** MediaConvert reads the bucket itself, so video never passes through a worker. FFmpeg is the local stand-in and writes the same ladder and layout; poster, sprite and VTT come from the same code after either.
- **Delivery:** only `media/` is readable through CloudFront, for a year, so a changed file has a changed address. Originals are private for ever.
- **Failure:** three attempts with backoff, then `failed`, visible in the library with a Retry button. Abandoned uploads, rejected and deleted files are pruned every six hours.
- The worker that opens files runs under its own role, which cannot send mail, encrypt secrets or write audit anchors.

## Alternatives
Uploading through the API (ties up workers, cannot resume); ClamAV on Fargate (large signature memory, scans gigabytes through a container); transcoding with FFmpeg in production (long CPU-bound tasks that a deployment interrupts).

## Consequences
The real MediaConvert and GuardDuty paths are proven against stubs only until there is an AWS account (A8, A10).
