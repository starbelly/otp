[
  application: :index,
  extras:
    [
      "README.md",
      "man_index.md",
      "../general_info/deprecations.md",
      "../general_info/removed.md",
      "../general_info/scheduled_for_removal.md",
      "../general_info/upcoming_incompatibilities.md",
      "system/installation_guide.md",
      "system/getting_started.md",
      "system/system_principles.md",
      "system/programming_examples.md",
      "system/reference_manual.md",
      "system/design_principles.md",
      "system/efficiency_guide.md",
      "system/embedded.md",
      "system/oam.md"
    ] ++
      Path.wildcard("{core,database,oam,interfaces,tools,testing,documentation}/*.md"),
  main: "readme",
  api_reference: false,
  groups_for_extras: [
    "System Documentation": ~r{system},
    Core: ~r/core/,
    Database: ~r/database/,
    "Operations & Mainteinance": ~r/oam/,
    "Interfaces & Communication": ~r/interfaces/,
    Tools: ~r/tools/,
    Test: ~r/testing/,
    Documentation: ~r/documentation/
  ],
  skip_code_autolink_to: [
    "dbg:stop_clear/0",
    "net:broadcast/3",
    "net:call/4",
    "net:cast/4",
    "net:ping/1",
    "net:sleep/1",
    "net:broadcast/3",
    "net:call/4",
    "net:cast/4",
    "net:ping/1",
    "net:sleep/1"
  ],
  skip_undefined_reference_warnings_on: ["../general_info/removed.md"]
]