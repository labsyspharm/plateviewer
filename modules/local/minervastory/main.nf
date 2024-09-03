import groovy.json.JsonOutput


process MINERVASTORY {
    input:
    tuple val(meta), val(channel_metas)

    output:
    tuple val(meta), path('index.html'), emit: story
    path "versions.yml",                 emit: versions

    when:
    task.ext.when == null || task.ext.when

    exec:

    def colorCycle = [
        "0000ff",
        "00ff00",
        "ff0000",
        "00ffff",
        "ff00ff",
    ]

    def exhibit = [
      Images: [
        [
          Name: "i0",
          Description: "",
          Path: ".",
          Width: meta.width,
          Height: meta.height,
          MaxLevel: meta.levels
        ]
      ],
      Header: "",
      Rotation: 0,
      Layout: [
        Grid: [
          [
            "i0"
          ]
        ]
      ],
      Stories: [
        [
          Name: "",
          Description: "",
          Waypoints: []
        ]
      ],
      Channels: channel_metas.collect{ [Name: it.channel, Path: it.channel] },
        Groups: [
            [
                Name: "Overview",
                Colors: [colorCycle, channel_metas].transpose().collect{ it[0] },
                Channels: channel_metas.collect{ it.channel },
                Descriptions: channel_metas.collect{ '' }
            ]
        ],
        Masks: []
    ]
    def exhibitJson = JsonOutput.prettyPrint(JsonOutput.toJson(exhibit))

    file("${task.workDir}/index.html").text = """\
    <!DOCTYPE html>
    <html lang="en-US" class="h-100">

    <head>
      <meta charset='utf-8'>
      <meta http-equiv="X-UA-Compatible" content="IE=edge">
      <meta name="viewport" content="width=device-width, initial-scale=1">
    </head>

    <body>
        <div id="minerva-browser" style="position: absolute; top: 0; left: 0; height: 100%; width: 100%;"> </div>
        <script defer src="https://use.fontawesome.com/releases/v5.2.0/js/all.js" integrity="sha384-4oV5EgaV02iISL2ban6c/RmotsABqE4yZxZLcYMAdG7FAPsyHYAPpywE9PJo+Khy" crossorigin="anonymous"></script>
        <script src="https://cdn.jsdelivr.net/npm/minerva-browser@3.19.6/build/bundle.js"></script>
      <script>
            window.viewer = MinervaStory.default.build_page({
              hideWelcome: true,
              cellTypeData: [],
              markerData: [],
              exhibit: $exhibitJson,
              id: "minerva-browser",
              embedded: true
            });
        </script>
    </body>
    </html>
    """.stripIndent()

    file("${task.workDir}/versions.yml").text = """\
    "${task.process}":
        minervastory: 1.0.2
    """.stripIndent()
}
