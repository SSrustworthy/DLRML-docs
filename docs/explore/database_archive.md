# Database Archive

As a participant in the digital age, we are increasingly faced with the inevitable conclusion that the services we use and rely on will someday likely no longer be around. I hope to be maintaining this website for a long time to come, but in the event that Notion (the host for this website) goes away, I need a surefire solution to keep these track databases alive and kicking! This will ensure that the musical legacy of the Disneyland Resort can be shared with as many people as possible.

I have exported my databases to CSV/Markdown format, along with an archive of my longer loop research posts from MouseBits, and uploaded these to a GitHub repository (https://github.com/SSrustworthy/DLRML-tracklistings). I then created a release of these — basically, a snapshot of the repository, frozen in time — and added these to Zenodo, a scientific research site (which I’m not technically supposed to do, but these are pretty small files, and it integrates nicely with GitHub, so I did it anyways). 

Zenodo creates a digital object identifier to serve as a permanent link to the releases I host on GitHub. You can access the most recent track listing database permanently by going to this link:

![](https://zenodo.org/badge/DOI/10.5281/zenodo.7259055.svg)

[https://doi.org/10.5281/zenodo.7259055](https://doi.org/10.5281/zenodo.7259055)

You can download this repository at any time for your own personal archive.

# Accessing databases outside of Notion

Notion provides a useful tool to create and view databases. However, the size of these track listing databases can be a deterrent and slow down the viewing system. One alternative is to download the current repository and then use your CSV viewer of choice to filter loops and columns. One option is the [Tad viewer](https://www.tadviewer.com/), which is a fast tabular viewer that can be downloaded to your desktop.

# A note on formatting

[Markdown](https://en.wikipedia.org/wiki/Markdown) is a lightweight markup language for creating formatted text using a plain-text editor. Notion’s markdown export reliability [is not the best](https://www.markdownguide.org/tools/notion/). It seems that the Pandoc flavor of Markdown best aligns with the formatting, should you choose to look at my old posts in a Markdown compatible viewer.

One recommended platform to view and edit these Markdown notes is `VSCodium`, which is a version of Microsoft’s popular Visual Studio code editor compiled *without* the tracking code.

[VSCodium - Open Source Binaries of VSCode](https://vscodium.com/)

<aside>
📌 Microsoft’s `vscode` source code is open source (MIT-licensed), but the product available for download (Visual Studio Code) is licensed under this not-FLOSS license and contains telemetry/tracking. According to this comment from a Visual Studio Code maintainer:

> When we [Microsoft] build Visual Studio Code, we do exactly this. We clone the vscode repository, we lay down a customized product.json that has Microsoft specific functionality (telemetry, gallery, logo, etc.), and then produce a build that we release under our license.
> When you clone and build from the vscode repo, none of these endpoints are configured in the default product.json. Therefore, you generate a “clean” build, without the Microsoft customizations, which is by default licensed under the MIT license.

The VSCodium project exists so that you don’t have to download+build from source. This project includes special build scripts that clone Microsoft’s vscode repo, run the build commands, and upload the resulting binaries for you to GitHub releases. These binaries are licensed under the MIT license. Telemetry is disabled.

</aside>