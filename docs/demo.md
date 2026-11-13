# Screencast outline

Record once the remote runs exist. Use 1920 × 1080 or higher, 16:9, a legible terminal font and clear narration. Target four minutes.

| Time | Show | Say |
| --- | --- | --- |
| 0:00–0:25 | Azure sign-in and opening Bash Cloud Shell, without recording authentication details | The repository is built and tested here before it is delivered. |
| 0:25–1:05 | Git clone, commit and green `make all` output | The Makefile runs install, lint and tests. |
| 1:05–1:40 | GitHub Actions run and commit | GitHub replays those checks on a fresh runner. |
| 1:40–2:30 | Azure Pipelines Validate and Deploy stages and the running App Service | Azure packages the same source revision, tests it and deploys the archive. |
| 2:30–3:35 | Run the prediction from Cloud Shell and show the matching App Service logs | The JSON and `X-Revision` connect the HTTP result to the deployed artifact. |
| 3:35–4:00 | README, plan and board | The README gives the reviewer the commands and proof links. |

Link the uploaded screencast in the README. Check that the reviewer can access the link. Use the pipeline run for the demonstration of continuous delivery and Cloud Shell for the prediction capture.
