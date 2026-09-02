#!/usr/bin/env ruby

require "find"
require "json"
require "yaml"

ROOT = File.expand_path("..", __dir__)
THEME_PATH = File.join(ROOT, "themes", "macos_system7.yaml")
CHICAGO_WEB_PATH = File.join(ROOT, "assets", "Chicago.woff")
GENEVA_PATH = File.join(ROOT, "assets", "Geneva.ttf")
FONT_CSS_PATH = File.join(ROOT, "assets", "fonts.css")
README_PATH = File.join(ROOT, "README.md")
VERSION_PATH = File.join(ROOT, "VERSION")
HACS_PATH = File.join(ROOT, "hacs.json")
NOTICES_PATH = File.join(ROOT, "THIRD_PARTY_NOTICES.md")
LICENSE_PATH = File.join(ROOT, "LICENSE")
VALIDATE_WORKFLOW_PATH = File.join(ROOT, ".github", "workflows", "validate.yml")
RELEASE_WORKFLOW_PATH = File.join(ROOT, ".github", "workflows", "release.yml")
SCREENSHOT_PATHS = %w[
  mobile-dashboard.jpg
  color-dashboard.jpg
  system-dialog.png
  eink-display.jpg
].map { |name| File.join(ROOT, "images", name) }.freeze
REQUIRED_README_LINKS = %w[
  https://github.com/Lint-Free-Technology/uix
  https://github.com/thomasloven/lovelace-card-mod
  https://github.com/Clooos/Bubble-Card
  https://github.com/custom-cards/bar-card
  https://github.com/kalkih/mini-graph-card
  https://github.com/kalkih/mini-media-player
  https://github.com/kalkih/simple-weather-card
  https://github.com/nervetattoo/simple-thermostat
  https://github.com/iantrich/text-divider-row
  https://github.com/custom-cards/stack-in-card
  https://github.com/ofekashery/vertical-stack-in-card
  https://github.com/dmellok/tesserae
].freeze
MONO_THEME_NAME = "MacOS System 7 eink theme"
COLOR_THEME_NAME = "MacOS System 7 color theme"
GLOBAL_UIX_KEYS = %w[uix-card-yaml uix-row-yaml uix-more-info-yaml uix-dialog-yaml uix-root-yaml uix-config-yaml].freeze
BUILTIN_STACK_UIX_HOSTS = %w[
  &hui-horizontal-stack-card
  &hui-vertical-stack-card
].freeze
CUSTOM_STACK_CHILD_SELECTOR = "ha-card > div > *"
CUSTOM_STACK_UIX_HOSTS = %w[
  &stack-in-card
  &vertical-stack-in-card
].freeze
STACK_SLIDER_UIX_PATHS = %w[
  &hui-horizontal-stack-card\ #root\ $$\ ha-slider\ $
  &hui-vertical-stack-card\ #root\ $$\ ha-slider\ $
  &stack-in-card\ ha-card\ $$\ ha-slider\ $
  &vertical-stack-in-card\ ha-card\ $$\ ha-slider\ $
].freeze
STACK_TITLE_UIX_PATHS = %w[
  &stack-in-card\ ha-card\ $
  &vertical-stack-in-card\ ha-card\ $
].freeze
def assert(condition, message)
  raise message unless condition
end

def declarations_for_selector_group(css, *required_selectors)
  css.scan(/([^{}]+)\s*\{([^{}]*)\}/m).each do |selectors, declarations|
    selector_set = selectors.split(",").map(&:strip)
    return declarations if required_selectors.all? { |required| selector_set.include?(required) }
  end
  nil
end

def declarations_for_exact_selector_group(css, *required_selectors)
  css.scan(/([^{}]+)\s*\{([^{}]*)\}/m).each do |selectors, declarations|
    return declarations if selectors.split(",").map(&:strip) == required_selectors
  end
  nil
end

assert(File.file?(THEME_PATH), "missing theme file: #{THEME_PATH}")
assert(Dir.glob(File.join(ROOT, "themes", "*.yaml")) == [THEME_PATH], "HACS theme repositories must ship one managed YAML file")
assert(File.file?(CHICAGO_WEB_PATH), "missing uploaded Chicago webfont: #{CHICAGO_WEB_PATH}")
assert(File.file?(GENEVA_PATH), "missing Geneva font: #{GENEVA_PATH}")
assert(File.file?(FONT_CSS_PATH), "missing document-level font stylesheet: #{FONT_CSS_PATH}")
assert(File.file?(README_PATH), "missing public README: #{README_PATH}")
assert(File.file?(VERSION_PATH), "missing release version: #{VERSION_PATH}")
assert(File.file?(HACS_PATH), "missing HACS metadata: #{HACS_PATH}")
assert(File.file?(NOTICES_PATH), "missing third-party notices: #{NOTICES_PATH}")
assert(File.file?(LICENSE_PATH), "missing project license: #{LICENSE_PATH}")
assert(File.file?(VALIDATE_WORKFLOW_PATH), "missing HACS validation workflow")
assert(File.file?(RELEASE_WORKFLOW_PATH), "missing tag release workflow")
SCREENSHOT_PATHS.each { |path| assert(File.file?(path), "missing screenshot: #{path}") }
assert(!File.exist?(File.join(ROOT, "assets", "ChicagoFLF.ttf")), "unused all-rights-reserved ChicagoFLF.ttf must not ship")

version = File.read(VERSION_PATH).strip
readme = File.read(README_PATH)
hacs = JSON.parse(File.read(HACS_PATH))
notices = File.read(NOTICES_PATH)
license = File.read(LICENSE_PATH)
validate_workflow = File.read(VALIDATE_WORKFLOW_PATH)
release_workflow = File.read(RELEASE_WORKFLOW_PATH)
assert(version == "1.0.1", "documentation correction release must be 1.0.1")
assert(version.match?(/\A\d+\.\d+\.\d+\z/), "VERSION must use semantic versioning")
assert(hacs == { "name" => "MacOS System 7 Theme", "filename" => "macos_system7.yaml" }, "HACS metadata must select the combined System 7 theme file")
assert(readme.include?("@v#{version}/assets/fonts.css"), "README install URLs must follow VERSION")
assert(readme.include?(MONO_THEME_NAME) && readme.include?(COLOR_THEME_NAME), "README must name both installable themes")
assert(readme.downcase.include?("ai robots") && readme.downcase.include?("e-ink"), "README must carry the AI/e-ink project warning")
assert(readme.scan(/^> /).length <= 2, "AI/e-ink warning must stay concise")
assert(readme.include?("UIX is required") && readme.include?("card-mod is not required"), "README must describe UIX as the sole styling dependency")
assert(!readme.include?("/config/www") && !readme.include?("curl -L"), "font setup must not require copying files into Home Assistant")
assert(readme.include?("https://cdn.jsdelivr.net/gh/skynet01/homeassistant-macos-system7-theme@v#{version}/assets/fonts.css"), "README must use the versioned hosted font stylesheet")
REQUIRED_README_LINKS.each { |url| assert(readme.include?(url), "README missing upstream link: #{url}") }
SCREENSHOT_PATHS.each do |path|
  relative = path.delete_prefix("#{ROOT}/")
  assert(readme.include?(relative), "README missing screenshot reference: #{relative}")
end
assert(readme.include?("<table>") && readme.scan(/<tr>/).length == 2, "README screenshots must use a compact two-row table")
assert(notices.include?("Chicago.woff") && notices.include?("Geneva.ttf"), "third-party notices must identify both bundled fonts")
assert(notices.include?("not covered by the GNU GPL"), "font notice must exclude third-party binaries from the project GPL grant")
assert(license.include?("GNU GENERAL PUBLIC LICENSE") && license.include?("Version 3"), "project-owned work must remain GPL-3.0")
assert(release_workflow.include?('tags:') && release_workflow.include?('"v*"'), "release workflow must be tag-driven")
assert(release_workflow.include?('VERSION'), "release workflow must verify the tag against VERSION")
assert(release_workflow.include?('GH_REPO: ${{ github.repository }}'), "release workflow must identify the repository without a checkout")
assert(validate_workflow.include?('tags-ignore:') && validate_workflow.include?('"v*"'), "branch validation must not duplicate tag release jobs")
[validate_workflow, release_workflow].each do |workflow|
  assert(workflow.include?("hacs/action@1ebf01c408f29afcb6406bd431bc98fd8cbb15aa"), "HACS validation action must be pinned")
  assert(!workflow.include?("hacs/action@main"), "HACS validation action must not use a mutable branch")
end

forbidden_public_paths = []
Find.find(ROOT) do |path|
  if File.directory?(path) && File.basename(path) == ".git"
    Find.prune
  else
    relative = path.delete_prefix("#{ROOT}/")
    forbidden_public_paths << path if relative.match?(/(?:^|\/)(?:\.env|backups?|handoffs?)(?:$|\/)/i) || relative.match?(/(?:\.bak|~)\z/i)
  end
end
assert(forbidden_public_paths.empty?, "private or backup artifacts must not ship: #{forbidden_public_paths.join(', ')}")

theme_document = YAML.safe_load_file(THEME_PATH, aliases: true)

assert(theme_document.keys == [MONO_THEME_NAME, COLOR_THEME_NAME], "managed theme file must expose both System 7 variants")

theme = theme_document.fetch(MONO_THEME_NAME)
color_theme = theme_document.fetch(COLOR_THEME_NAME)
structural_keys = theme.keys.grep(/\A(?:uix|card-mod)-(?!theme\z)/)
effective_color_theme = theme.merge(color_theme)
theme_variants = {
  MONO_THEME_NAME => theme,
  COLOR_THEME_NAME => effective_color_theme,
}
raw = File.read(THEME_PATH)
bw_raw = theme.to_yaml
font_css = File.read(FONT_CSS_PATH)

missing_color_keys = (theme.keys - structural_keys) - color_theme.keys
assert(missing_color_keys.empty?, "color theme lost shared non-structural keys: #{missing_color_keys.sort.join(', ')}")
assert(!raw.include?("<<: *macintosh_eink_base"), "Home Assistant does not resolve YAML merge inheritance for themes")
assert(theme["card-mod-theme"] == MONO_THEME_NAME, "card-mod-theme must match the theme name")
assert(theme["uix-theme"] == MONO_THEME_NAME, "uix-theme must match the theme name")
assert(color_theme["card-mod-theme"] == MONO_THEME_NAME, "color theme must reuse the monochrome card-mod structure")
assert(color_theme["uix-theme"] == MONO_THEME_NAME, "color theme must reuse the monochrome UIX structure")
assert((color_theme.keys & structural_keys).empty?, "color theme must not duplicate shared UIX/card-mod CSS")
assert(theme["macintosh-global-filter"] == "grayscale(1)", "monochrome theme must grayscale the whole frontend")
assert(color_theme["macintosh-global-filter"] == "none", "color theme must preserve System 7 colors")
assert(color_theme["primary-color"] != theme["primary-color"], "color theme must override the monochrome semantic palette")
assert(color_theme["blue-color"] != color_theme["green-color"], "color theme needs distinct System 7 semantic colors")
assert(color_theme["macintosh-slider-active-color"] == "#0000aa", "color controls must use the System 7 blue active token")

surfaces = %w[primary-background-color secondary-background-color card-background-color].map { |key| theme.fetch(key) }
assert(surfaces.uniq.length == surfaces.length, "desktop, chrome, and card surfaces must use different gray shades")
assert(theme["primary-text-color"] == "#000000", "primary text must be black")
assert(theme["ha-card-border-radius"] == "0px", "cards must use square classic Mac corners")
assert(theme["ha-card-border-width"] == "1px", "cards must use a one-pixel System 7 frame")
assert(theme["ha-card-box-shadow"] == "3px 3px 0 #000000", "tiles must use a slightly larger hard one-bit shadow")
assert(theme["ha-view-sections-column-gap"] == "20px", "tiles need twenty pixels of horizontal spacing")
assert(theme["ha-view-sections-row-gap"] == "20px", "tiles need twenty pixels of vertical spacing")
assert(theme["ha-view-sections-narrow-column-gap"] == "20px", "section spacing must survive narrow layouts")
assert(theme["masonry-view-card-margin"] == "10px", "masonry cards need universal twenty-pixel gaps")
assert(theme["stack-card-gap"] == "20px", "stacked cards need universal twenty-pixel gaps")

font_family = theme.fetch("primary-font-family")
assert(font_family.include?("GenevaSystem"), "theme must use Geneva for body text")
body_font_family = theme.fetch("macintosh-body-font-family")
assert(body_font_family.include?("GenevaSystem"), "theme must expose a dedicated Geneva body-font token")
assert(theme.fetch("macintosh-title-font-family").include?("ChicagoWeb"), "theme must use the uploaded Chicago webfont for titles")
assert(font_css.include?('url("./Chicago.woff")'), "hosted stylesheet must load the bundled Chicago webfont relatively")
assert(font_css.include?('url("./Geneva.ttf")'), "hosted stylesheet must load the bundled Geneva body font relatively")
assert(font_css.include?('font-family: "ChicagoWeb"'), "font stylesheet must register the uploaded Chicago webfont")
assert(font_css.include?('font-family: "GenevaSystem"'), "font stylesheet must register GenevaSystem")

hex_colors = bw_raw.scan(/#[0-9a-fA-F]{3,8}\b/).map(&:downcase).uniq
non_grayscale_hex = hex_colors.reject do |value|
  rgb = value.delete_prefix("#")
  rgb = rgb.chars.map { |channel| channel * 2 }.join if [3, 4].include?(rgb.length)
  next false unless [6, 8].include?(rgb.length)

  channels = rgb[0, 6].scan(/../).map { |channel| channel.to_i(16) }
  channels.uniq.length == 1
end
assert(non_grayscale_hex.empty?, "non-grayscale colors found: #{non_grayscale_hex.join(', ')}")

gray_hex = hex_colors.select do |value|
  rgb = value.delete_prefix("#")
  rgb = rgb.chars.map { |channel| channel * 2 }.join if [3, 4].include?(rgb.length)
  next false unless [6, 8].include?(rgb.length)

  channels = rgb[0, 6].scan(/../).map { |channel| channel.to_i(16) }
  channels.uniq.length == 1 && ![0, 255].include?(channels.first)
end
assert(gray_hex.length >= 4, "theme must provide a useful e-ink grayscale ramp")

rgb_colors = bw_raw.scan(/rgba?\(([^)]*)\)/i).flatten
unexpected_rgb = rgb_colors.reject do |value|
  channels = value.split(",").first(3).map { |channel| channel.strip.to_i }
  channels.uniq.length == 1
end
assert(unexpected_rgb.empty?, "non-grayscale RGB colors found: #{unexpected_rgb.join(', ')}")

animation_values = raw.scan(/animation:\s*([^;]+);/).flatten.map(&:strip)
assert(animation_values.all? { |value| value == "none !important" }, "e-ink theme must not animate")
assert(raw.include?("ha-switch") && raw.include?("ha-control-switch"), "left-side switch rules are missing")
assert(raw.include?(".state") && raw.include?("order: -1"), "left-side state rules are missing")
assert(raw.include?("ha-radio-option") && raw.include?("ha-radio") && raw.include?("mwc-radio") && raw.include?("md-radio"), "radio controls need a cross-generation style path")
assert(raw.include?("ha-radio-option::part(control)") && raw.include?("--ha-radio-option-checked-icon-scale: 0"), "current radio options must render as square filled checkboxes")
assert(raw.include?(".mdc-radio__outer-circle") && raw.include?("border-radius: 0 !important"), "radio controls must look like square checkboxes")
assert(raw.include?("hui-generic-entity-row $"), "native entity-row shadow styling is missing")
assert(raw.include?(".row > slot") && raw.include?("order: -3"), "entity controls and states must lead the row")
assert(theme["ha-switch-width"] == "18px", "switches must use a compact System 7 square")
assert(theme["ha-switch-size"] == "18px", "switches must use a compact System 7 square")
assert(theme["ha-switch-min-touch-size"] == "40px", "compact switches must retain a functional touch target")
assert(theme["ha-switch-checked-thumb-background-color"] == "#000000", "on switches must be visibly filled")
assert(theme["ha-switch-thumb-background-color"] == "#ffffff", "off switches must remain visibly empty")
assert(raw.include?("repeating-linear-gradient"), "classic Macintosh title-bar stripes are missing")
assert(theme.fetch("macintosh-titlebar-background").include?("repeating-linear-gradient"), "title-bar stripe token is missing")
assert(theme.fetch("macintosh-titlebar-background").include?("#ffffff 0 3px"), "title bars need a white upper reveal")
assert(theme.fetch("macintosh-titlebar-background").include?("#ffffff 16px 100%"), "title bars need a white lower reveal")
assert(theme["macintosh-title-label-background"] == "#ffffff", "striped title labels need a pure-white backing")
assert(color_theme["macintosh-title-label-background"] == "#ffffff", "color-theme title labels need the same pure-white backing")
assert(theme.fetch("macintosh-direct-titlebar-background").include?("var(--macintosh-title-label-background)"), "direct title bars must use the dedicated white label backing")
assert(!theme.fetch("macintosh-direct-titlebar-background").include?("var(--macintosh-surface)"), "direct-text title bars must not inherit the gray card surface")
assert(theme.fetch("macintosh-direct-titlebar-background").include?("var(--macintosh-titlebar-background)"), "direct-text title bars must retain the striped System 7 chrome")
assert(raw.include?(":host ha-card > .card-header"), "card-mod 4 host-path title styling is missing")
assert(raw.include?(".card-header::before") && raw.include?(".card-header::after"), "title bars need distinct close and zoom boxes")
assert(raw.include?("macintosh-titlebar-zoom-box"), "the right title-bar box needs its nested zoom mark")
%w[uix-card-yaml card-mod-card].each do |key|
  card_css = theme.fetch(key)
  assert(card_css.match?(/ha-card > \.card-header[^\{]*\{[^\}]*margin:\s*0 0 12px !important/m), "#{key} card title bars need a twelve-pixel content gap")
  assert(card_css.match?(/ha-card > \.card-header[^\{]*\{[^\}]*font-size:\s*var\(--macintosh-title-font-size\) !important/m), "#{key} card title bars must consume the shared title-size token")
  mini_graph_name = card_css[/mini-graph-card\) ha-card > \.header \.name\s*\{([^\}]*)\}/m, 1]
  assert(mini_graph_name&.include?("background: var(--macintosh-title-label-background) !important"), "#{key} Mini Graph title labels need a pure-white backing")
  assert(mini_graph_name&.include?("color: var(--macintosh-black) !important"), "#{key} Mini Graph titles must use the ordinary black title color")
  mini_graph_text = card_css[/:host\(mini-graph-card\) ha-card > \.header \.name > span\s*\{([^\}]*)\}/m, 1]
  assert(mini_graph_text&.include?("opacity: 1 !important"), "#{key} Mini Graph title text must stay fully opaque like ordinary card titles")
  assert(card_css.match?(/ha-card > \.card-header > \.name[^\{]*\{[^\}]*background:\s*var\(--macintosh-title-label-background\) !important/m), "#{key} card-header title labels need a pure-white backing")
end
assert(raw.include?(":host(mini-graph-card) ha-card > .header .name"), "mini graph titles must use a scoped Chicago rule")
assert(raw.include?(":host(simple-thermostat) .header__title"), "Mini Thermostat titles must use Chicago")
assert(raw.include?(":host(text-divider-row)"), "text divider labels must use Chicago")
%w[uix-row-yaml card-mod-row-yaml].each do |key|
  divider_css = theme.fetch(key)
  assert(divider_css.match?(/:host\(text-divider-row\) \.text-divider span\s*\{[^\}]*line-height:\s*0 !important/m), "#{key} must use the requested zero-height divider line")
end
assert(font_css.scan(/font-family: [\"']ChicagoWeb[\"']/).length == 1, "Chicago must have one document-level registration")

assert(theme["macintosh-title-font-size"] == "15px", "System 7 title text must use the requested 15px token")
assert(theme["macintosh-section-title-font-size"] == "18px", "non-dashboard page and section titles need the requested readable size")
assert(theme["ha-card-header-font-size"] == "var(--macintosh-title-font-size)", "native card headers must consume the shared title-size token")
assert(theme["title-font-size"] == "var(--macintosh-title-font-size)", "generic titles must consume the shared title-size token")
assert(theme["ha-heading-card-title-font-size"] == "var(--macintosh-title-font-size)", "heading-card titles must consume the shared title-size token")
assert(theme.fetch("uix-more-info-yaml").match?(/\.title[^\{]*\{[^\}]*font-size:\s*var\(--macintosh-title-font-size\) !important/m), "more-info titles must consume the shared title-size token")
assert(theme.fetch("card-mod-more-info").include?("font-size: var(--macintosh-title-font-size) !important"), "legacy more-info titles must consume the shared title-size token")
assert(!raw.match?(/font-size:\s*18px !important/), "dialog title sizing must use the shared token instead of literal 18px declarations")

title_blocks = raw.scan(/\{[^{}]*font-family:\s*var\(--macintosh-title-font-family\)[^{}]*\}/m)
gray_title_blocks = title_blocks.reject { |block| block.match?(/color:\s*(?:var\(--macintosh-black\)|#000000)\s*!important/) }
assert(gray_title_blocks.empty?, "every Chicago text rule must force black text")
assert(theme["mdc-typography-button-font-family"] == "var(--macintosh-title-font-family)", "buttons must use Chicago")
assert(theme["ha-button-border-radius"] == "var(--macintosh-button-radius)", "buttons must use the shared rounded System 7 radius")

parsed_yaml_by_theme = theme_variants.to_h do |name, candidate|
  parsed_yaml_by_key = candidate.keys.grep(/-yaml\z/).to_h do |key|
    assert(candidate.fetch(key).is_a?(String), "#{name} #{key} must be an embedded YAML string")
    parsed_yaml = YAML.safe_load(candidate.fetch(key), aliases: true)
    assert(parsed_yaml.is_a?(Hash), "#{name} #{key} must contain valid selector YAML")
    [key, parsed_yaml]
  end
  [name, parsed_yaml_by_key]
end
parsed_yaml_by_key = parsed_yaml_by_theme.fetch(MONO_THEME_NAME)
uix_card_root_css = parsed_yaml_by_key.fetch("uix-card-yaml").fetch(".")
mobile_divider_block = <<~CSS.rstrip
  @media (max-width: 600px) {
    #states > div > text-divider-row {
      overflow: visible !important;
    }
  }
CSS
assert(uix_card_root_css.include?(mobile_divider_block), "mobile entity-card dividers must escape Home Assistant's clipping boundary")
assert(!uix_card_root_css.sub(mobile_divider_block, "").include?("#states > div > text-divider-row"), "divider overflow exception must remain mobile-only and targeted")

theme_variants.each do |name, candidate|
  theme_tree = parsed_yaml_by_theme.fetch(name)

  assert(candidate["sidebar-selected-icon-color"] == "var(--macintosh-dark-gray)", "#{name} selected sidebar icons must remain visible gray")
  assert(candidate["sidebar-selected-text-color"] == "#000000", "#{name} selected sidebar text must remain independently readable")
  assert(candidate["ha-button-box-shadow"] == "1px 1px 0 var(--macintosh-black)", "#{name} buttons must inherit the System 7 hard shadow")
  assert(candidate["macintosh-dialog-title-font-size"] == "18px", "#{name} modal titles need the requested larger size")
  assert(candidate["macintosh-dialog-action-height"] == "40px", "#{name} modal actions need the shared primary-button height")
  assert(candidate.fetch("card-mod-dialog").include?("font-size: var(--macintosh-dialog-title-font-size) !important"), "#{name} legacy dialog titles must consume the dedicated modal title-size token")
  assert(candidate["macintosh-default-button-radius"] == "30px", "#{name} accent buttons need a shared rounded default-button radius")
  default_button_shadow = candidate.fetch("macintosh-default-button-shadow")
  assert(default_button_shadow == "inset 0 0 0 2px var(--macintosh-surface), inset 0 0 0 3px var(--macintosh-black), 2px 2px 0 var(--macintosh-black)", "#{name} accent buttons need the complete shared double-ring shadow")
  assert(candidate["ha-icon-button-size"] == "40px", "#{name} icon buttons need compact System 7 geometry")
  assert(candidate["macintosh-plain-button-shadow"] == "2px 2px 0 var(--macintosh-black)", "#{name} plain buttons need the requested two-pixel hard shadow")
  assert(candidate["macintosh-icon-button-height"] == "27px", "#{name} corner icon buttons need the requested height")
  assert(candidate["macintosh-icon-button-width"] == "31px", "#{name} corner icon buttons need the requested width")
  assert(candidate["macintosh-icon-button-radius"] == "5px", "#{name} corner icon buttons need the requested radius")
  assert(candidate["macintosh-icon-button-gap"] == "5px", "#{name} corner icon buttons need the requested spacing")
  expected_header_offset = name == MONO_THEME_NAME ? "0px" : "var(--ha-sidebar-width, 0px)"
  assert(candidate["macintosh-header-start-offset"] == expected_header_offset, "#{name} needs the correct fixed-header coordinate-space offset")
  %w[ha-color-fill-primary-loud-resting ha-color-fill-primary-loud-hover ha-color-fill-primary-loud-active].each do |key|
    assert(candidate[key] == "var(--macintosh-surface)", "#{name} #{key} must keep footer actions on a visible System 7 surface")
  end
  assert(candidate["ha-color-on-primary-loud"] == "#000000", "#{name} footer action labels and icons must remain black and visible")
  assert(candidate["wa-color-brand-border-loud"] == "var(--ha-color-border-loud)", "#{name} footer actions must retain the black brand border token")

  root_tree = theme_tree.fetch("uix-root-yaml")
  assert(root_tree.keys.none? { |path| path.include?("home-assistant-main") || path.include?("hui-root") }, "#{name} uix-root paths must be relative to UIX's live hui-root anchor")
  lovelace_chrome_css = root_tree.fetch(".")
  header_rule = lovelace_chrome_css[/\.header\s*\{([^\}]*)\}/m, 1]
  assert(header_rule&.include?("inset-inline: var(--macintosh-header-start-offset, 0px) 0 !important"), "#{name} Lovelace header must use the variant-aware coordinate-space offset")
  assert(header_rule&.include?("width: auto !important"), "#{name} Lovelace header width must derive from its logical insets")
  assert(!header_rule.include?("width: 100% !important"), "#{name} Lovelace header must not add a full viewport width after the sidebar offset")
  assert(lovelace_chrome_css.match?(/\.toolbar\s*\{[^\}]*padding-inline-end:\s*12px !important/m), "#{name} Lovelace toolbar needs safe space after the final action")
  assert(lovelace_chrome_css.match?(/\.action-items\s*\{[^\}]*gap:\s*6px !important/m), "#{name} Lovelace action buttons need six pixels of separation")
  navbar_trigger_rule = declarations_for_exact_selector_group(lovelace_chrome_css, '.action-items ha-icon-button[slot="trigger"]')
  assert(navbar_trigger_rule&.include?("position: relative !important") && navbar_trigger_rule.include?("inset-block-start: 3px !important"), "#{name} navbar trigger buttons must align with ordinary action buttons")
  assert(lovelace_chrome_css.match?(/\.main-title\s*\{[^\}]*font-family:\s*var\(--macintosh-title-font-family\) !important/m), "#{name} must reach the Lovelace top-nav title")
  fixed_app_bar_css = root_tree.fetch("ha-top-app-bar-fixed $")
  assert(fixed_app_bar_css.match?(/\.title\s*\{[^\}]*font-family:\s*var\(--macintosh-title-font-family\) !important/m), "#{name} must reach current fixed top-app-bar titles")

  sidebar_css = candidate.fetch("card-mod-sidebar")
  assert(sidebar_css.match?(/\.title\s*\{[^\}]*font-family:\s*var\(--macintosh-title-font-family\) !important/m), "#{name} must use Chicago for the visible Home Assistant navigation title")
  assert(sidebar_css.match?(/\.title\s*\{[^\}]*color:\s*var\(--macintosh-black\) !important/m), "#{name} sidebar Chicago title must remain black")
  assert(!sidebar_css.match?(/^\s*ha-list-item-button\s*\{/m), "#{name} expanded sidebar rows must remain unboxed")
  card_mod_sidebar_toggle_rule = declarations_for_exact_selector_group(sidebar_css, ":host(:not([expanded])) .menu > ha-icon-button")
  assert(card_mod_sidebar_toggle_rule&.include?("margin-inline-start: 8px !important"), "#{name} card-mod fallback must center the collapsed sidebar toggle")
  sidebar_button_rule = sidebar_css[/:host\(:not\(\[expanded\]\)\) ha-list-item-button\s*\{([^\}]*)\}/m, 1]

  sidebar_root_css = theme_tree.fetch("uix-sidebar-yaml").fetch(".", "")
  sidebar_toggle_rule = declarations_for_exact_selector_group(sidebar_root_css, ":host(:not([expanded])) .menu > ha-icon-button")
  assert(sidebar_toggle_rule&.include?("margin-inline-start: 8px !important"), "#{name} collapsed sidebar toggle must center its visible button frame")
  uix_sidebar_button_rule = declarations_for_exact_selector_group(sidebar_root_css, ":host(:not([expanded])) ha-list-item-button")
  {
    "card-mod" => sidebar_button_rule,
    "UIX" => uix_sidebar_button_rule,
  }.each do |surface, rule|
    assert(rule&.include?("border: 1px solid var(--macintosh-black) !important"), "#{name} #{surface} must frame collapsed sidebar rows")
    assert(rule&.include?("border-radius: var(--macintosh-icon-button-radius) !important"), "#{name} #{surface} collapsed sidebar rows need the requested radius")
    assert(rule&.include?("box-shadow: 1px 1px 1px var(--macintosh-black) !important"), "#{name} #{surface} collapsed sidebar rows need the requested shadow")
    assert(rule&.include?("margin-inline-start: 2px !important"), "#{name} #{surface} collapsed sidebar rows need the requested leading space")
  end

  toolbar_button_css = root_tree.fetch(".action-items ha-icon-button $").fetch("ha-button $")
  assert(toolbar_button_css.include?(':host([appearance="plain"]) [part~="base"]'), "#{name} Lovelace action buttons must target the exact plain-button host through its public base part")
  assert(toolbar_button_css.include?("border: 2px solid var(--macintosh-black) !important"), "#{name} Lovelace action buttons need the requested two-pixel frame")
  assert(toolbar_button_css.include?("box-shadow: 2px 2px 0 var(--macintosh-black) !important"), "#{name} Lovelace action buttons need the stronger toolbar shadow")
  assert(toolbar_button_css.include?("border-radius: var(--macintosh-icon-button-radius) !important"), "#{name} Lovelace action buttons must keep the compact System 7 radius")
  assert(toolbar_button_css.include?("height: var(--macintosh-icon-button-height) !important"), "#{name} Lovelace action buttons need the requested compact height")

  GLOBAL_UIX_KEYS.each do |key|
    button_css = theme_tree.fetch(key).fetch("ha-button $")
    base_rule = button_css[/\[part~="base"\]\s*\{([^\}]*)\}/m, 1]
    assert(base_rule&.include?("border: 1px solid var(--macintosh-black) !important"), "#{name} #{key} default buttons need a visible frame")
    assert(base_rule&.include?("box-shadow: var(--ha-button-box-shadow) !important"), "#{name} #{key} default buttons need the shared hard shadow")
    accent_rule = button_css[/:host\(\[appearance~="accent"\]\) \[part~="base"\]\s*\{([^\}]*)\}/m, 1]
    assert(accent_rule, "#{name} #{key} must reach accent button internals")
    assert(accent_rule.include?("border: 2px solid var(--macintosh-black) !important"), "#{name} #{key} accent buttons need the outer default-button ring")
    assert(accent_rule.include?("border-radius: var(--macintosh-default-button-radius) !important"), "#{name} #{key} accent buttons must use the shared default-button radius")
    assert(accent_rule.include?("font-family: var(--macintosh-title-font-family) !important"), "#{name} #{key} accent buttons must use Chicago")
    assert(accent_rule.include?("box-shadow: var(--macintosh-default-button-shadow) !important"), "#{name} #{key} accent buttons must consume the shared double-ring shadow")
    plain_rule = declarations_for_selector_group(
      button_css,
      ':host([appearance="plain"]) [part~="base"]',
      ':host([appearance~="plain"]) .button',
    )
    assert(plain_rule, "#{name} #{key} must reach public and legacy plain-button internals with one shared rule")
    assert(plain_rule.include?("height: var(--macintosh-icon-button-height) !important"), "#{name} #{key} plain buttons need the requested 27px height token")
    assert(plain_rule.include?("border: 2px solid var(--macintosh-black) !important"), "#{name} #{key} plain buttons need the requested two-pixel frame")
    assert(plain_rule.include?("border-radius: var(--macintosh-icon-button-radius) !important"), "#{name} #{key} plain buttons need the requested five-pixel radius token")
    assert(plain_rule.include?("box-shadow: var(--macintosh-plain-button-shadow) !important"), "#{name} #{key} plain buttons need the shared two-pixel shadow")
    small_rule = button_css[/:host\(\[size="s"\]\) \[part~="base"\]\s*\{([^\}]*)\}/m, 1]
    assert(small_rule, "#{name} #{key} must reach size-s button internals")
    assert(small_rule.include?("border: 2px solid var(--macintosh-black) !important"), "#{name} #{key} size-s buttons need the requested two-pixel frame")
    assert(small_rule.include?("border-radius: 25px !important"), "#{name} #{key} size-s buttons need the requested 25px radius")
    assert(small_rule.include?("font-family: var(--macintosh-title-font-family) !important"), "#{name} #{key} size-s buttons must use the Chicago theme variable")
    assert(small_rule.include?("color: var(--macintosh-black) !important"), "#{name} #{key} size-s Chicago text must remain black")
    icon_button_tree = theme_tree.fetch(key).fetch("ha-icon-button $")
    nested_plain_css = icon_button_tree.fetch("ha-button $")
    nested_plain_rule = declarations_for_selector_group(
      nested_plain_css,
      ':host([appearance="plain"]) [part~="base"]',
      ':host([appearance~="plain"]) .button',
    )
    assert(nested_plain_rule, "#{name} #{key} must cross ha-icon-button's nested ha-button shadow root")
    assert(nested_plain_rule.include?("height: var(--macintosh-icon-button-height) !important"), "#{name} #{key} nested plain buttons need the requested 27px height token")
    assert(nested_plain_rule.include?("border: 2px solid var(--macintosh-black) !important"), "#{name} #{key} nested plain buttons need the requested two-pixel frame")
    assert(nested_plain_rule.include?("border-radius: var(--macintosh-icon-button-radius) !important"), "#{name} #{key} nested plain buttons need the requested five-pixel radius token")
    assert(nested_plain_rule.include?("box-shadow: var(--macintosh-plain-button-shadow) !important"), "#{name} #{key} nested plain buttons need the shared two-pixel shadow")
    assert(nested_plain_rule.include?("width: var(--macintosh-icon-button-width) !important"), "#{name} #{key} nested plain buttons need the shared compact width")
    assert(nested_plain_rule.include?("margin-inline-end: var(--macintosh-icon-button-gap) !important"), "#{name} #{key} nested plain buttons need logical spacing")
  end

  outer_card_layers = {
    "uix-card-yaml" => theme_tree.fetch("uix-card-yaml").fetch("."),
    "card-mod-card" => candidate.fetch("card-mod-card"),
  }
  outer_card_layers.each do |key, css|
    %w[stack-in-card vertical-stack-in-card].each do |host|
      host_rule = css[/:host\(#{Regexp.escape(host)}\)[^\{]*\{([^\}]*)\}/m, 1]
      reset_outer_surface = host_rule&.match?(/background:\s*transparent !important|border:\s*0 !important|box-shadow:\s*none !important/)
      assert(!reset_outer_surface, "#{name} #{key} must preserve the outer #{host} surface and frame")
    end
  end

  card_tree = theme_tree.fetch("uix-card-yaml")
  BUILTIN_STACK_UIX_HOSTS.each do |path|
    assert(!card_tree.key?(path), "#{name} #{path} must not strip the only surface and frame from built-in stack children")
  end
  CUSTOM_STACK_UIX_HOSTS.each do |path|
    stack_css = card_tree.fetch(path)
    child_rule = stack_css[/#{Regexp.escape(CUSTOM_STACK_CHILD_SELECTOR)}\s*\{([^\}]*)\}/m, 1]
    assert(child_rule, "#{name} #{path} must target the stack's direct child card hosts")
    assert(child_rule.include?("--card-background-color: transparent !important"), "#{name} #{path} nested cards must inherit a transparent surface")
    assert(child_rule.include?("--ha-card-border-width: 0px !important"), "#{name} #{path} nested custom cards must not double the wrapper frame")
    assert(child_rule.include?("--ha-card-box-shadow: none !important"), "#{name} #{path} nested custom cards must not double the wrapper shadow")
  end
  STACK_SLIDER_UIX_PATHS.each do |slider_path|
    slider_css = card_tree.fetch(slider_path)
    assert(slider_css.include?("border: 1px solid var(--macintosh-black) !important"), "#{name} #{slider_path} nested knobs need a black frame")
    assert(slider_css.include?("box-shadow: 1px 1px 0 var(--macintosh-black) !important"), "#{name} #{slider_path} nested knobs need the System 7 hard shadow")
  end
  STACK_TITLE_UIX_PATHS.each do |path|
    title_css = card_tree.fetch(path)
    title_rule = title_css[/\.card-header\s*\{([^\}]*)\}/m, 1]
    assert(title_rule&.include?("background: var(--macintosh-direct-titlebar-background) !important"), "#{name} #{path} titled custom stacks need stripes with a solid backing behind their direct text")
    assert(title_rule&.include?("font-family: var(--macintosh-title-font-family) !important"), "#{name} #{path} titled custom stacks need Chicago")
    assert(title_rule&.include?("font-size: var(--macintosh-title-font-size) !important"), "#{name} #{path} titled custom stacks need the shared title size")
    assert(title_rule&.include?("margin: 0 0 12px !important"), "#{name} #{path} titled custom stacks need the normal card content gap")
    assert(title_css.include?(".card-header::before") && title_css.include?(".card-header::after"), "#{name} #{path} titled custom stacks need both System 7 corner boxes")
  end
  invalid_host_hops = card_tree.keys.grep(/^&(?:hui-horizontal-stack-card|hui-vertical-stack-card|stack-in-card|vertical-stack-in-card) \$/)
  assert(invalid_host_hops.empty?, "#{name} stack paths must not try to enter a second shadow root immediately after a leading host filter: #{invalid_host_hops.join(', ')}")

  mini_graph_css = card_tree.fetch(".")
  mini_graph_card = mini_graph_css[/:host\(mini-graph-card\) ha-card\s*\{([^\}]*)\}/m, 1]
  assert(mini_graph_card&.include?("padding-top: 0 !important"), "#{name} Mini Graph Card must remove its native 16px space above the title bar")
  mini_graph_header = mini_graph_css[/:host\(mini-graph-card\) ha-card > \.header\s*\{([^\}]*)\}/m, 1]
  assert(mini_graph_header&.include?("background: var(--macintosh-titlebar-background) !important"), "#{name} Mini Graph Card headers need the striped System 7 bar")
  assert(mini_graph_header&.include?("margin: 0 0 12px !important"), "#{name} Mini Graph Card title bars need the normal content gap")
  assert(mini_graph_css.include?(":host(mini-graph-card) ha-card > .header::before") && mini_graph_css.include?(":host(mini-graph-card) ha-card > .header::after"), "#{name} Mini Graph Card title bars need both corner boxes")
  mini_graph_name = mini_graph_css[/:host\(mini-graph-card\) ha-card > \.header \.name[^\{]*\{([^\}]*)\}/m, 1]
  assert(mini_graph_name&.include?("background: var(--macintosh-title-label-background) !important"), "#{name} Mini Graph Card titles need a pure-white backing over the stripes")
  assert(mini_graph_name&.include?("font-family: var(--macintosh-title-font-family) !important"), "#{name} Mini Graph Card titles need Chicago")
  card_mod_mini_graph = candidate.fetch("card-mod-card")[/:host\(mini-graph-card\) ha-card\s*\{([^\}]*)\}/m, 1]
  assert(card_mod_mini_graph&.include?("padding-top: 0 !important"), "#{name} card-mod fallback must remove Mini Graph Card's native 16px title-bar offset")

  titlebar_layers = {
    "uix-card-yaml" => mini_graph_css,
    "card-mod-card" => candidate.fetch("card-mod-card"),
  }
  titlebar_layers.each do |key, css|
    graph_header = css[/:host\(mini-graph-card\) ha-card > \.header\s*\{([^\}]*)\}/m, 1]
    assert(graph_header&.include?("padding: 1px 22px 0 !important"), "#{name} #{key} Mini Graph title bars need the requested compact inset")
    graph_icon = css[/:host\(mini-graph-card\) ha-card > \.header \.icon\s*\{([^\}]*)\}/m, 1]
    assert(graph_icon&.include?("position: absolute !important"), "#{name} #{key} Mini Graph icons must leave the title-bar flex layout")
    assert(graph_icon&.include?("top: calc(100% + 8px) !important"), "#{name} #{key} Mini Graph icons must sit below the System 7 title bar")
    assert(graph_icon&.include?("right: 16px !important"), "#{name} #{key} Mini Graph icons need the normal card content inset")
    card_header = css[/:host ha-card > \.card-header,[^\{]*\{([^\}]*)\}/m, 1]
    assert(card_header&.include?("padding: 1px 22px 0 !important"), "#{name} #{key} normal card title bars need the requested compact inset")
  end

  group_header_layers = {
    "uix-config-yaml" => theme_tree.fetch("uix-config-yaml").fetch("* $").fetch("hass-tabs-subpage-data-table $").fetch("ha-data-table $").fetch("."),
    "card-mod-view" => candidate.fetch("card-mod-view"),
  }
  group_header_layers.each do |key, css|
    group_header_icon = css[/\.group-header ha-icon-button\s*\{([^\}]*)\}/m, 1]
    assert(group_header_icon&.include?("transition: transform 0.2s !important"), "#{name} #{key} config group icons need the requested transform transition")
    assert(group_header_icon&.include?("margin-inline-end: 14px !important"), "#{name} #{key} config group icons need the requested logical right spacing")
  end

  card_mod_surface = candidate.fetch("card-mod-card")[/:host ha-card,\s*ha-card\s*\{([^\}]*)\}/m, 1]
  assert(card_mod_surface&.include?("border: var(--ha-card-border-width) solid var(--ha-card-border-color) !important"), "#{name} card-mod fallback must honor inherited stack border width")

  bubble_layers = {
    "uix-card-yaml" => theme_tree.fetch("uix-card-yaml").fetch("."),
    "card-mod-card" => candidate.fetch("card-mod-card"),
  }
  bubble_layers.each do |key, css|
    direct_bubble_rule = css[/^\s*\.bubble-sub-button:not\(\.bubble-sub-button-slider\)\s*\{([^\}]*)\}/m, 1]
    assert(direct_bubble_rule, "#{name} #{key} must style Bubble sub-buttons directly inside Bubble Card's shadow root")
    assert(direct_bubble_rule.include?("border-radius: var(--macintosh-button-radius) !important"), "#{name} #{key} Bubble sub-buttons must inherit the rounded System 7 button shape")
  end

  %w[uix-card-yaml card-mod-card-yaml].each do |key|
    card_tree = theme_tree.fetch(key)
    nested_slider_css = card_tree.fetch("mmp-media-controls $").fetch("ha-slider $")
    assert(nested_slider_css.include?("border: 1px solid var(--macintosh-black) !important"), "#{name} #{key} must reach Mini Media Player slider knob borders")
    assert(nested_slider_css.include?("box-shadow: 1px 1px 0 var(--macintosh-black) !important"), "#{name} #{key} must reach Mini Media Player slider knob shadows")

    stacked_divider_css = card_tree.fetch("text-divider-row $")
    assert(stacked_divider_css.include?("font-family: var(--macintosh-title-font-family) !important"), "#{name} #{key} must style text dividers loaded directly by stack cards")
  end

  GLOBAL_UIX_KEYS.each do |key|
    slider_css = theme_tree.fetch(key).fetch("ha-slider $")
    assert(slider_css.include?("border: 1px solid var(--macintosh-black) !important"), "#{name} #{key} must apply the global slider knob border")
    assert(slider_css.include?("box-shadow: 1px 1px 0 var(--macintosh-black) !important"), "#{name} #{key} must apply the global slider knob shadow")
  end

  more_info_tree = theme_tree.fetch("uix-more-info-yaml")
  more_info_info_tree = more_info_tree.fetch("ha-more-info-info $")
  state_card_tree = more_info_info_tree.fetch("state-card-content $")
  number_slider_css = state_card_tree.fetch("state-card-number $").fetch("ha-slider $")
  input_number_slider_css = state_card_tree.fetch("state-card-input_number $").fetch("ha-slider $")
  media_slider_css = more_info_info_tree.fetch("more-info-content $").fetch("more-info-media_player $").fetch("ha-slider $")
  [number_slider_css, input_number_slider_css, media_slider_css].each do |slider_css|
    assert(slider_css.include?("box-shadow: 1px 1px 0 var(--macintosh-black) !important"), "#{name} must reach every nested popup slider")
  end

  %w[ha-more-info-info\ $ ha-more-info-history-and-logbook\ $].each do |path|
    activity_css = more_info_tree.fetch(path).fetch("ha-more-info-logbook $")
    assert(activity_css.include?("font-family: var(--macintosh-title-font-family) !important"), "#{name} #{path} Activity headings must use Chicago")
  end

  config_tree = theme_tree.fetch("uix-config-yaml")
  integration_title_css = config_tree.fetch("ha-config-integrations-dashboard $").fetch("ha-integration-card $").fetch("ha-integration-header $")
  assert(integration_title_css.include?(".primary") && integration_title_css.include?("font-family: var(--macintosh-title-font-family) !important"), "#{name} integration dashboard titles must use Chicago")

  dialog_tree = theme_tree.fetch("uix-dialog-yaml")
  dialog_header_blocks = [
    dialog_tree.fetch("&ha-adaptive-dialog $").fetch("ha-dialog $").fetch("ha-dialog-header $"),
    dialog_tree.fetch("&ha-dialog $").fetch("ha-dialog-header $"),
  ]
  dialog_header_blocks.each do |header_css|
    header_bar_rule = declarations_for_exact_selector_group(header_css, ".header-bar")
    assert(header_bar_rule&.include?("min-height: 38px !important"), "#{name} modal headers need room around the title and close control")
    assert(header_bar_rule&.include?("padding: 4px 8px !important"), "#{name} modal headers need balanced System 7 padding")
    header_content_rule = declarations_for_exact_selector_group(header_css, ".header-content")
    assert(header_content_rule&.include?("min-height: 28px !important"), "#{name} modal header content needs a stable inner height")
    assert(header_content_rule&.include?("padding: 3px 8px !important"), "#{name} modal header content needs breathing room")
    title_rule = header_css[/\.header-title,\s*\.header-title ::slotted\(\*\)\s*\{([^\}]*)\}/m, 1]
    assert(title_rule&.include?("font-size: var(--macintosh-dialog-title-font-size) !important"), "#{name} modal header titles must use the dedicated 18px token")
    assert(title_rule&.include?("padding-inline-start: 0 !important"), "#{name} modal header titles must remove leading padding")
    assert(header_css.match?(/\.header-navigation-icon\s*\{[^\}]*order:\s*1 !important/m), "#{name} modal close navigation must move to the far right")
  end
  close_button_paths = ["&ha-adaptive-dialog $", "&ha-dialog $"]
  close_button_paths.each do |path|
    close_base_css = dialog_tree.fetch(path).fetch("ha-icon-button $").fetch("ha-button $")
    close_base_rule = declarations_for_selector_group(close_base_css, ':host([appearance="plain"]) [part~="base"]', ':host([appearance~="plain"]) .button')
    assert(close_base_rule&.include?("width: 24px !important") && close_base_rule.include?("height: 24px !important"), "#{name} #{path} must explicitly size the close-button base")
    assert(close_base_rule&.include?("border: 1px solid var(--macintosh-black) !important"), "#{name} #{path} close buttons need a complete black frame")
    assert(close_base_rule&.include?("border-radius: 0 !important"), "#{name} #{path} close-button base must be square")
    assert(close_base_rule&.include?("box-shadow: var(--ha-button-box-shadow) !important"), "#{name} #{path} close buttons need the shared System 7 hard shadow")
  end

  dialog_button_css = dialog_tree.fetch("ha-button $")
  shared_action_rule = declarations_for_selector_group(dialog_button_css, ':host([slot="primaryAction"]) [part~="base"]', ':host([slot="secondaryAction"]) [part~="base"]')
  assert(shared_action_rule&.include?("height: var(--macintosh-dialog-action-height) !important") && shared_action_rule.include?("min-height: var(--macintosh-dialog-action-height) !important"), "#{name} dialog actions must share the dialog-action height")
  assert(shared_action_rule&.include?("border-radius: var(--macintosh-default-button-radius) !important"), "#{name} dialog actions must share the default pill shape")
  primary_action_rule = declarations_for_exact_selector_group(dialog_button_css, ':host([slot="primaryAction"]) [part~="base"]', ':host([slot="primaryAction"]) .button')
  assert(primary_action_rule&.include?("border: 2px solid var(--macintosh-black) !important"), "#{name} dialog primary actions need the double-button outer frame")
  assert(primary_action_rule&.include?("box-shadow: var(--macintosh-default-button-shadow) !important"), "#{name} dialog primary actions need the double-ring shadow")
  secondary_action_rule = declarations_for_exact_selector_group(dialog_button_css, ':host([slot="secondaryAction"]) [part~="base"]', ':host([slot="secondaryAction"]) .button')
  assert(secondary_action_rule&.include?("border: 1px solid var(--macintosh-black) !important"), "#{name} secondary actions need a complete single-pixel frame")
  assert(secondary_action_rule&.include?("box-shadow: var(--macintosh-plain-button-shadow) !important"), "#{name} secondary actions need the shared hard shadow without the primary double ring")

  add_label_css = dialog_tree.fetch("ha-labels-picker $").fetch("ha-button#picker $")
  add_label_rule = declarations_for_selector_group(add_label_css, ':host(#picker) [part~="base"]', ':host(#picker) .button')
  assert(add_label_rule&.include?("border: 1px solid var(--macintosh-black) !important"), "#{name} Add label needs a visible one-pixel frame")
  assert(add_label_rule&.include?("box-shadow: var(--ha-button-box-shadow) !important"), "#{name} Add label needs the shared System 7 hard shadow")

  dialog_yaml = candidate.fetch("uix-dialog-yaml")
  assert(!dialog_yaml.include?('data-dialog="close"'), "#{name} must not restore the non-resolving data-dialog close path")
  assert(!dialog_yaml.match?(/^\s*"[^\n]*\$\$[^\n]*(?:primaryAction|secondaryAction)/), "#{name} must not restore non-resolving double-hop action paths")

  bar_value_surfaces = {
    "uix-card-yaml" => theme_tree.fetch("uix-card-yaml").fetch("."),
    "uix-row-yaml" => theme_tree.fetch("uix-row-yaml").fetch("."),
    "card-mod-card" => candidate.fetch("card-mod-card"),
    "card-mod-row-yaml" => theme_tree.fetch("card-mod-row-yaml").fetch("."),
  }
  bar_value_surfaces.each do |key, bar_value_css|
    bar_value_rule = bar_value_css[/bar-card-value\s*\{([^\}]*)\}/m, 1]
    assert(bar_value_rule&.include?("font-family: var(--macintosh-title-font-family) !important"), "#{name} #{key} bar-card values must use Chicago")
    assert(bar_value_rule&.include?("color: var(--macintosh-black) !important"), "#{name} #{key} bar-card values must remain black")
  end
end

assert(theme.fetch("uix-dialog-yaml").include?("ha-adaptive-dialog"), "adaptive dialogs need a UIX style path")
assert(raw.include?("ha-dialog-header $"), "dialog title-bar shadow styling is missing")
assert(raw.include?(".header-bar"), "dialog header bar styling is missing")
assert(raw.include?(".main"), "more-info title styling is missing")

assert(theme["bar-card-border-radius"] == "4px", "bar rows must use rounded System 7 corners")
assert(theme["bar-card-color"] != "#000000", "bar fill must use gray instead of flat black")
assert(theme.fetch("macintosh-progress-background").include?("repeating-conic-gradient"), "bar tracks must use a static dither pattern")
assert(theme.fetch("macintosh-progress-fill").include?("repeating-conic-gradient"), "progress fills must use a darker static dither pattern")
assert(theme.fetch("macintosh-progress-fill").include?("var(--macintosh-dark-gray)"), "progress fill dither must use a lighter dark-gray phase")
assert(theme.fetch("macintosh-progress-fill").include?("var(--macintosh-mid-gray)"), "progress fill dither must use a lighter mid-gray phase")
assert(!theme.fetch("macintosh-progress-background").include?("var(--macintosh-black)"), "progress track dither must remain visibly lighter than the fill")
assert(theme.fetch("macintosh-progress-background").include?("var(--macintosh-control)"), "progress tracks must use the barely-visible control gray")
assert(theme.fetch("macintosh-progress-background").include?("var(--macintosh-platinum)"), "progress tracks must use a slightly darker platinum phase")
assert(theme["ha-progress-bar-indicator-background"] == "var(--macintosh-progress-fill)", "native progress bars must consume the dark dither fill")
assert(raw.match?(/bar-card-backgroundbar\s*\{[^\}]*background:\s*var\(--macintosh-progress-background\) !important/m), "bar-card must consume the dithered track token")
assert(!raw.match?(/bar-card-currentbar\s*\{[^\}]*background:/m), "bar-card currentbar must retain its native percentage-masked gradient")
currentbar_block = raw[/bar-card-currentbar\s*\{([^\}]*)\}/m, 1]
currentbar_opacity = currentbar_block&.match(/opacity:\s*([0-9.]+) !important/)&.captures&.first&.to_f
assert(currentbar_opacity && currentbar_opacity.positive? && currentbar_opacity < 1, "bar-card fills must be lightened without replacing the percentage mask")
assert(raw.match?(/:host\(bar-card\) ha-card[^\{]*\{[^\}]*box-shadow:\s*none !important/m), "bar-card must not receive a card shadow")
assert(theme["ha-list-item-border-color"] == "transparent", "ordinary entity rows must not gain separator borders")
assert(raw.include?(":host(bubble-card)"), "Bubble Card needs a scoped row treatment")
assert(raw.include?("--bubble-border: none !important"), "Bubble Card rows must not draw divider borders")
assert(raw.match?(/:host\(bubble-card\) ha-card[^\{]*\{[^\}]*border:\s*0 !important;[^\}]*box-shadow:\s*none !important;/m), "Bubble Card's outer ha-card must not draw row separators")
assert(raw.match?(/\.bubble-sub-button:not\(\.bubble-sub-button-slider\):not\(:has\([^\{]+\)\)\s*\{\s*display:\s*none !important;/m), "empty Bubble sub-buttons must be removed from layout")
bubble_button_blocks = raw.scan(/\.bubble-sub-button:not\(\.bubble-sub-button-slider\)\s*\{([^\}]*)\}/m).flatten
assert(bubble_button_blocks.any? { |block| block.include?("box-shadow: 1px 1px 0 var(--macintosh-black) !important") }, "Bubble buttons need a hard System 7 shadow")
assert(bubble_button_blocks.all? { |block| block.include?("font-family: var(--macintosh-title-font-family) !important") && block.include?("color: var(--macintosh-black) !important") }, "visible Bubble buttons must use black Chicago text")
assert(bubble_button_blocks.none? { |block| block.match?(/\bbackground\s*:/) }, "Bubble buttons must not overwrite camera-feed background images")
thermostat_blocks = %w[uix-card-yaml card-mod-card].map { |key| theme.fetch(key) }
assert(thermostat_blocks.all? { |css| css.match?(/:host\(simple-thermostat\) ha-card\s*\{[^\}]*border-left:\s*0 !important/m) }, "Mini Thermostat cards must remove the nested left border")
assert(thermostat_blocks.all? { |css| css.match?(/:host\(simple-thermostat\) \.current--value[^\{]*\{[^\}]*font-family:\s*var\(--macintosh-title-font-family\) !important/m) }, "Mini Thermostat temperatures must use Chicago")
assert(raw.include?('var(--macintosh-body-font-family, GenevaSystem, Geneva, Verdana, "DejaVu Sans", sans-serif)'), "injected Geneva declarations need a shadow-root-safe fallback")
assert(theme["paper-slider-knob-color"] == "#ffffff", "legacy slider knobs must be white")
assert(theme["paper-slider-active-color"] == "var(--macintosh-slider-active-color)", "legacy slider fill must use the shared active-control token")
assert(theme["paper-slider-container-color"] == "var(--macintosh-control)", "legacy slider tracks must stay very light")
assert(theme["md-slider-inactive-track-color"] == "var(--macintosh-control)", "inactive slider tracks must stay very light")
assert(theme["md-slider-active-track-color"] == "var(--macintosh-slider-active-color)", "active slider tracks must use the shared active-control token")
%w[md-slider-handle-color md-slider-focus-handle-color md-slider-hover-handle-color md-slider-pressed-handle-color].each do |key|
  assert(theme[key] == "#ffffff", "#{key} must keep the slider knob white")
end
assert(theme["md-slider-handle-shape"] == "50%", "slider knobs must remain circular")
assert(theme["md-slider-handle-shadow-color"] == "#000000", "slider knobs need a black System 7 shadow")
assert(theme["md-slider-handle-elevation"] == "1px 1px 0 #000000", "slider knobs need a visible hard shadow")
assert(theme["ha-slider-track-color"] == "var(--macintosh-control)", "current HA slider tracks must stay very light")
assert(theme["ha-slider-indicator-color"] == "var(--macintosh-slider-active-color)", "current HA slider fill must remain distinct")
assert(theme["ha-slider-thumb-color"] == "#ffffff", "current HA slider knobs must be white")
assert(theme["control-slider-background"] == "var(--macintosh-control)", "large control sliders need a light track")
assert(theme["control-slider-background-opacity"] == "1", "large control sliders must preserve the intended track shade")
assert(theme["control-slider-color"] == "var(--macintosh-slider-active-color)", "large control sliders need the shared filled portion")
row_slider_css = theme.fetch("card-mod-row-yaml")
assert(row_slider_css.match?(/ha-slider\s*\{[^\}]*--md-slider-active-track-color:\s*var\(--macintosh-slider-active-color\) !important;[^\}]*--md-slider-inactive-track-color:\s*var\(--macintosh-control\) !important;/m), "entity-row sliders must retain distinct active and very-light inactive tracks")
assert(!row_slider_css.match?(/--md-slider-(?:handle|focused-handle|focus-handle|hover-handle|pressed-handle)-color:\s*#000000/), "entity-row slider states must not turn the knob black")
assert(raw.match?(/\.bubble-range-slider\s*\{[^\}]*background:\s*var\(--macintosh-progress-background\) !important/m), "Bubble slider tracks must use the dither token")
assert(raw.match?(/\.bubble-range-fill\s*\{[^\}]*background:\s*var\(--macintosh-slider-active-color\) !important/m), "Bubble slider fills must use the shared active-control token")
assert(theme["ha-color-neutral-60"] != "#ffffff", "input placeholders must remain visible on white fields")
assert(theme["text-accent-color"] == "#ffffff", "sidebar notification badges need contrasting text")

root_css = theme.fetch("uix-root-yaml")
config_css = theme.fetch("uix-config-yaml")
assert(theme.fetch("card-mod-sidebar").include?(".badge"), "sidebar styling must reach the notification badge on its live surface")
assert(root_css.include?("hass-subpage $") && root_css.include?(".main-title"), "page titles beside back arrows must use the universal title path")
theme_variants.each do |name, candidate|
  parsed_theme = parsed_yaml_by_theme.fetch(name)
  %w[uix-root-yaml uix-config-yaml].each do |key|
    subpage_css = parsed_theme.fetch(key).fetch("hass-subpage $")
    main_title_rule = subpage_css[/\.main-title\s*\{([^\}]*)\}/m, 1]
    assert(main_title_rule&.include?("font-family: var(--macintosh-title-font-family) !important"), "#{name} #{key} non-dashboard page titles must use Chicago")
    assert(main_title_rule&.include?("font-size: var(--macintosh-section-title-font-size) !important"), "#{name} #{key} non-dashboard page titles must use the readable section-title size")
    assert(main_title_rule&.include?("padding-inline-start: 8px !important"), "#{name} #{key} non-dashboard page titles need modest leading space")
  end
  config_tree = parsed_theme.fetch("uix-config-yaml")
  %w[ha-config-entities\ $$\ ha-button\ $ ha-config-integrations-dashboard\ $$\ ha-button\ $].map { |path| path.gsub("\\ ", " ") }.each do |path|
    universal_config_button_css = config_tree.fetch(path)
    assert(universal_config_button_css.include?("border: 1px solid var(--macintosh-black) !important"), "#{name} #{path} needs the shared UIX frame")
    assert(universal_config_button_css.include?("box-shadow: var(--ha-button-box-shadow) !important"), "#{name} #{path} needs the shared UIX shadow")
    assert(universal_config_button_css.include?(':host([appearance="plain"]) [part~="base"]'), "#{name} #{path} must preserve plain-button chrome")
  end
  data_table_button_path = "ha-config-entities $ hass-tabs-subpage-data-table $ ha-data-table $ ha-icon-button $"
  data_table_button_css = config_tree.fetch(data_table_button_path).fetch("ha-button $")
  assert(data_table_button_css.include?('[part~="base"]'), "#{name} data-table buttons must use the public button part")
  assert(data_table_button_css.include?("border: 2px solid var(--macintosh-black) !important"), "#{name} data-table buttons need a visible frame")
  assert(data_table_button_css.include?("box-shadow: var(--macintosh-plain-button-shadow) !important"), "#{name} data-table buttons need the shared hard shadow")
  data_table_tree = config_tree.fetch("* $").fetch("hass-tabs-subpage-data-table $").fetch("ha-data-table $")
  entity_group_css = data_table_tree.fetch(".")
  entity_group_rule = entity_group_css[/\.group-header\s*\{([^\}]*)\}/m, 1]
  assert(entity_group_rule&.include?("font-family: var(--macintosh-title-font-family) !important"), "#{name} data-table group headers must use one universal retryable UIX path")
  assert(entity_group_rule&.include?("font-size: var(--macintosh-section-title-font-size) !important"), "#{name} entity data-table group headers must use the readable section-title size")
  assert(entity_group_rule&.include?("padding-inline-start: 8px !important"), "#{name} entity data-table group headers need modest leading space")
  config_descendants = config_tree.fetch("* $")
  deep_config_button_css = config_descendants.fetch("ha-button $")
  assert(deep_config_button_css.include?(':host([appearance="plain"]) [part~="base"]'), "#{name} direct config buttons need public-part styling")
  assert(deep_config_button_css.include?("border: 2px solid var(--macintosh-black) !important"), "#{name} direct config plain buttons need a visible frame")
  assert(deep_config_button_css.include?("box-shadow: var(--macintosh-plain-button-shadow) !important"), "#{name} direct config plain buttons need the shared hard shadow")
  assert(config_descendants.fetch("* $$ ha-button $").include?("border: 1px solid var(--macintosh-black) !important"), "#{name} deeply nested config buttons need default chrome")
  integration_page_tree = config_tree.fetch("ha-config-integration-page $")
  assert(integration_page_tree.is_a?(Hash), "#{name} integration page styling must split late-loading UIX paths into retryable levels")
  integration_page_css = integration_page_tree.fetch(".")
  integration_button_rule = declarations_for_exact_selector_group(integration_page_css, "ha-button::part(base)")
  assert(integration_button_rule&.include?("border: 1px solid var(--macintosh-black) !important"), "#{name} direct integration buttons need a persistent frame")
  assert(integration_button_rule&.include?("border-radius: var(--macintosh-button-radius) !important"), "#{name} direct integration buttons need the System 7 radius")
  assert(integration_button_rule&.include?("box-shadow: var(--ha-button-box-shadow) !important"), "#{name} direct integration buttons need the shared shadow")
  assert(integration_button_rule&.include?("font-family: var(--macintosh-title-font-family) !important"), "#{name} direct integration buttons need Chicago")
  integration_accent_rule = declarations_for_exact_selector_group(integration_page_css, 'ha-button[appearance~="accent"]::part(base)')
  assert(integration_accent_rule&.include?("background: var(--macintosh-surface) !important"), "#{name} integration accent buttons need the System 7 surface")
  assert(integration_accent_rule&.include?("border: 2px solid var(--macintosh-black) !important"), "#{name} integration accent buttons need the double-button frame")
  assert(integration_accent_rule&.include?("border-radius: var(--macintosh-default-button-radius) !important"), "#{name} integration accent buttons need the pill radius")
  assert(integration_accent_rule&.include?("box-shadow: var(--macintosh-default-button-shadow) !important"), "#{name} integration accent buttons need the double-button shadow")
  integration_icon_css = integration_page_tree.fetch("ha-icon-button $")
  integration_entry_tree = integration_page_tree.fetch("ha-config-entry-row $")
  integration_device_tree = integration_entry_tree.fetch("ha-config-entry-device-row $")
  {
    "header" => integration_icon_css,
    "entry" => integration_entry_tree.fetch("ha-icon-button $"),
    "device" => integration_device_tree.fetch("ha-icon-button $"),
  }.each do |surface, css|
    integration_icon_rule = declarations_for_exact_selector_group(css, "ha-button::part(base)")
    assert(integration_icon_rule&.include?("border: 2px solid var(--macintosh-black) !important"), "#{name} integration #{surface} actions need persistent frames")
    assert(integration_icon_rule&.include?("border-radius: var(--macintosh-icon-button-radius) !important"), "#{name} integration #{surface} actions need the compact radius")
    assert(integration_icon_rule&.include?("box-shadow: var(--macintosh-plain-button-shadow) !important"), "#{name} integration #{surface} actions need the hard shadow")
    assert(integration_icon_rule&.include?("height: var(--macintosh-icon-button-height) !important"), "#{name} integration #{surface} actions need the compact height")
  end
  device_page_css = config_tree.fetch("ha-config-device-page $")
  add_to_rule = declarations_for_exact_selector_group(device_page_css, ".card-header ha-button::part(base)")
  assert(add_to_rule&.include?("border: 1px solid var(--macintosh-black) !important"), "#{name} Add to needs a System 7 frame")
  assert(add_to_rule&.include?("box-shadow: 1px 1px 0 var(--macintosh-black) !important"), "#{name} Add to needs a System 7 shadow")
  row_tree = parsed_theme.fetch("uix-row-yaml")
  cover_button_css = row_tree.fetch("&hui-cover-entity-row").fetch("ha-cover-controls $").fetch("ha-icon-button $").fetch("ha-button $")
  assert(cover_button_css.include?(':host([appearance="plain"]) [part~="base"]'), "#{name} cover controls need a deep public-part route")
  sidebar_tree = parsed_theme.fetch("uix-sidebar-yaml")
  sidebar_button_css = sidebar_tree.fetch("ha-icon-button $").fetch("ha-button $")
  assert(sidebar_button_css.include?("border: 2px solid var(--macintosh-black) !important"), "#{name} sidebar icon buttons need a visible frame")
  assert(sidebar_button_css.include?("box-shadow: var(--macintosh-plain-button-shadow) !important"), "#{name} sidebar icon buttons need the shared hard shadow")
  group_rules = candidate.values.grep(String).flat_map { |css| css.scan(/\.group-header\s*\{([^\}]*)\}/m).flatten }
  assert(!group_rules.empty?, "#{name} must style data-table group headers")
  group_rules.each do |rule|
    assert(rule.include?("font-family: var(--macintosh-title-font-family) !important"), "#{name} group headers must use Chicago")
    assert(rule.include?("font-size: var(--macintosh-section-title-font-size) !important"), "#{name} group headers must use the readable section-title size")
    assert(rule.include?("padding-inline-start: 8px !important"), "#{name} group headers need modest leading space")
  end
end
%w[card-mod-root-yaml card-mod-config-yaml card-mod-view-yaml].each do |key|
  assert(!theme.key?(key), "#{key} must not duplicate the universal UIX data-table path")
end
assert(config_css.include?("ha-config-device-page $") && config_css.include?(".card-header"), "device Related headings need a config-wide Chicago path")
assert(config_css.include?("ha-related-items $") && config_css.include?("h3"), "related item headings need Chicago")
assert(config_css.include?("ha-config-integration-page $") && config_css.include?(".title h1"), "integration page titles need Chicago")
assert(config_css.include?("ha-config-entry-row $") && config_css.include?('[slot="headline"]'), "integration row titles need Chicago")

%w[uix-card-yaml card-mod-card-yaml].each do |key|
  card_tree = parsed_yaml_by_key.fetch(key)
  gauge_css = card_tree["ha-gauge $"]
  assert(gauge_css&.include?(".value-text") && gauge_css.include?("font-family: var(--macintosh-title-font-family) !important"), "#{key} must use Chicago for native gauge readings")
  card_css = card_tree.fetch(".")
  gauge_title_rule = card_css[/:host\(hui-gauge-card\) \.title(?:,[^\{]*)?\s*\{([^\}]*)\}/m, 1]
  assert(gauge_title_rule&.include?("font-family: var(--macintosh-title-font-family) !important"), "#{key} must use Chicago for native gauge titles")
end
assert(!theme.key?("macintosh-graph-background"), "Mini Graph cards must not define a special background")
theme_variants.each do |name, candidate|
  %w[uix-card-yaml card-mod-card].each do |key|
    card_css = candidate.fetch(key)
    weather_rule = card_css[/:host\(hui-weather-forecast-card\) ha-card,([^\{]*)\{([^\}]*)\}/m, 2]
    assert(weather_rule&.include?("font-family: var(--macintosh-title-font-family) !important"), "#{name} #{key} must use Chicago throughout the native weather card")
  end
end
%w[uix-card-yaml card-mod-card].each do |key|
  card_css = theme.fetch(key)
  assert(card_css.match?(/:host\(hui-sensor-card\)[^\{]*\{[^\}]*font-family:\s*var\(--macintosh-title-font-family\) !important/m), "#{key} must style every native sensor graph universally")
  assert(!card_css.match?(/:host\(mini-graph-card\) ha-card\s*\{[^\}]*background:/m), "#{key} must let Mini Graph cards inherit the normal card surface")
  assert(card_css.match?(/:host\(mini-graph-card\) \.state__value[^\{]*\{[^\}]*font-family:\s*var\(--macintosh-title-font-family\) !important/m), "#{key} must use Chicago for Mini Graph's large state numbers")
  assert(card_css.match?(/:host\(simple-weather-card\) \.weather__forecast\s*\{[^\}]*border-top:\s*0 !important/m), "#{key} must remove Simple Weather Card's center divider")
  weather_title = card_css[/:host\(simple-weather-card\) \.weather__info__title\s*\{([^\}]*)\}/m, 1]
  assert(weather_title&.include?("color: var(--macintosh-black) !important"), "#{key} must keep Simple Weather Card's title and temperature black")
  assert(weather_title&.include?("font-family: var(--macintosh-title-font-family) !important"), "#{key} must use Chicago for Simple Weather Card's title and temperature")
  assert(weather_title&.include?("font-weight: 400 !important"), "#{key} must use the Chicago webfont's native weight")
  assert(card_css.match?(/:host\(mini-media-player\) ha-card\.\-\-has-artwork\[artwork\*="cover"\]\s*\{[^\}]*color:\s*var\(--mmp-text-color\) !important/m), "#{key} must preserve Mini Media Player's own artwork-overlay contrast color")
end
assert(theme.fetch("card-mod-card").match?(/ha-card\s*\{[^\}]*box-shadow:\s*var\(--ha-card-box-shadow\) !important/m), "card-mod tiles must consume the shared larger shadow")

off_icon_paths = %w[uix-card-yaml uix-row-yaml card-mod-card card-mod-row-yaml].map { |key| theme.fetch(key) }
assert(off_icon_paths.all? { |css| css.include?('[data-state="off"]') && css.include?("mask-image: var(--macintosh-icon-dither) !important") }, "all card and row paths must dither off-state icons")
off_icon_shadow_paths = %w[uix-card-yaml uix-row-yaml card-mod-card-yaml card-mod-row-yaml].map { |key| theme.fetch(key) }
assert(off_icon_shadow_paths.all? { |css| css.include?('"state-badge $"') && css.match?(/ha-state-icon\[data-state="off"\][^\{]*\{[^\}]*mask-image:\s*var\(--macintosh-icon-dither\) !important/m) }, "all UIX/card-mod paths must reach state-badge's off icon shadow root")
assert(theme.fetch("macintosh-icon-dither").include?("transparent"), "off-state icon dither must alternate visible and transparent pixels")

more_info_paths = %w[uix-more-info-yaml card-mod-more-info].map { |key| theme.fetch(key) }
assert(more_info_paths.all? { |css| css.match?(/\.title \.main\s*\{[^\}]*order:\s*-1 !important/m) }, "popup main titles must appear above breadcrumbs")
assert(more_info_paths.all? do |css|
  breadcrumb = css[/\.title \.breadcrumb\s*\{([^\}]*)\}/m, 1]
  breadcrumb&.include?("order: 1 !important") && breadcrumb.include?("font-family: var(--macintosh-body-font-family")
end, "popup breadcrumbs must appear below the title in Geneva")
assert(more_info_paths.all? do |css|
  main = css[/\.title \.main\s*\{([^\}]*)\}/m, 1]
  main && !main.include?("border-bottom:") && !css.include?(".title .main::before")
end, "popup main titles must not use title-bar lines or dividers")
dialog_css = theme.fetch("uix-dialog-yaml")
assert(dialog_css.match?(/\.header-title[^\{]*\{[^\}]*background:\s*transparent !important/m), "popup title wrappers must not use the light-gray patch")
assert(dialog_css.match?(/\.header-navigation-icon,[^\{]*\.header-action-items\s*\{[^\}]*background:\s*transparent !important/m), "popup header controls must not use the light-gray patch")
assert(!dialog_css.include?("border-bottom: 1px solid var(--macintosh-black) !important"), "popup headers must not retain title-bar divider lines")
legacy_dialog_css = theme.fetch("card-mod-dialog")
assert(!legacy_dialog_css.match?(/^\s*h[12],?\s*$/), "legacy dialog styling must not turn content headings into title bars")
assert(legacy_dialog_css.match?(/\[slot="heading"\],[^\{]*\.mdc-dialog__title\s*\{[^\}]*background:\s*transparent !important/m), "legacy dialog titles must keep a white surface")
assert(!legacy_dialog_css.include?("[slot=\"heading\"]::before") && !legacy_dialog_css.include?("border-bottom:"), "legacy popup titles must not retain title-bar decoration")

history_tree = parsed_yaml_by_key.fetch("uix-more-info-yaml")
history_heading_blocks = ["ha-more-info-info $", "ha-more-info-history-and-logbook $"].map do |host_path|
  nested = history_tree[host_path]
  assert(nested.is_a?(Hash), "#{host_path} must be a retryable UIX History host path")
  block = nested["ha-more-info-history $"]
  assert(block.is_a?(String), "#{host_path} must cross the History heading shadow root in a separate retry step")
  block[/h2\s*\{([^\}]*)\}/m, 1]
end
assert(history_heading_blocks.any? && history_heading_blocks.all? { |block| block.include?("font-family: var(--macintosh-title-font-family) !important") && block.include?("color: var(--macintosh-black) !important") }, "History headings must use black Chicago text")
assert(theme["graph-color-1"] == "#000000", "the default History graph color must be black")

dialog_tree = parsed_yaml_by_key.fetch("uix-dialog-yaml")
popup_button_paths = {
  "&ha-adaptive-dialog $$ ha-icon-button $" => "ha-button::part(base)",
  "&ha-dialog $$ ha-icon-button $" => "ha-button::part(base)",
  "&ha-adaptive-dialog $$ ha-button $" => ".button",
  "&ha-dialog $$ ha-button $" => ".button",
}
popup_button_paths.each do |path, base_selector|
  block = dialog_tree[path]
  assert(block.is_a?(String) && block.include?(base_selector), "#{path} must reach the popup control base")
  %w[background border border-radius box-shadow color].each do |property|
    assert(block.match?(/^\s*#{Regexp.escape(property)}:/), "#{path} must define popup control #{property}")
  end
  assert(block.include?("border: 1px solid var(--macintosh-black) !important"), "#{path} must use a one-pixel black control border")
  assert(block.include?("border-radius: var(--macintosh-button-radius) !important"), "#{path} must use the shared System 7 control radius")
  assert(block.include?("box-shadow: 1px 1px 0 var(--macintosh-black) !important"), "#{path} must use a hard System 7 control shadow")
end
semantic_grays = %w[blue-color green-color yellow-color red-color].map { |key| theme.fetch(key) }
assert(semantic_grays.uniq.length == semantic_grays.length, "semantic colors must map to distinct gray shades")

synthetic_scrollbar_rules = [
  /overflow(?:-x|-y)?:\s*(?:scroll|auto)/,
  /scrollbar-gutter\s*:/,
]
assert(synthetic_scrollbar_rules.none? { |pattern| raw.match?(pattern) }, "theme must not force new scrollbars")
assert(raw.include?("::-webkit-scrollbar-thumb"), "native scrollbars must receive System 7 styling")
assert(raw.include?("scrollbar-color: #000000 #ffffff"), "Firefox scrollbars must receive monochrome styling")

puts "Macintosh theme contracts passed"
