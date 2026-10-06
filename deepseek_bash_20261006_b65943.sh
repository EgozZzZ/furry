#!/usr/bin/env bash
# FurryClient scaffold bootstrapper
# Creates the full 1.21.11 Fabric mod tree with placeholder files.
# Fill in file contents from the Turn 1 spec afterward.

set -e

BASE="src/main/java/dev/furry/client"

mkdir -p "$BASE/core/events"
mkdir -p "$BASE/module"
mkdir -p "$BASE/setting/settings"
mkdir -p "$BASE/gui"
mkdir -p "$BASE/mixin"
mkdir -p "src/main/resources"

touch gradle.properties
touch settings.gradle
touch build.gradle
touch README.md
touch .gitignore

cat > .gitignore <<'EOF'
.gradle/
build/
out/
*.iml
.idea/
run/
EOF

touch src/main/resources/fabric.mod.json
touch src/main/resources/furryclient.mixins.json

touch "$BASE/FurryClient.java"
touch "$BASE/core/EventBus.java"
touch "$BASE/core/ModuleManager.java"
touch "$BASE/core/ConfigManager.java"
touch "$BASE/core/KeybindManager.java"
touch "$BASE/core/events/Events.java"
touch "$BASE/module/Module.java"
touch "$BASE/setting/Setting.java"
touch "$BASE/setting/settings/BooleanSetting.java"
touch "$BASE/setting/settings/IntSetting.java"
touch "$BASE/setting/settings/DoubleSetting.java"
touch "$BASE/setting/settings/EnumSetting.java"
touch "$BASE/setting/settings/KeybindSetting.java"
touch "$BASE/gui/ClickGui.java"
touch "$BASE/mixin/ClientPlayNetworkHandlerMixin.java"
touch "$BASE/mixin/ClientPlayerEntityMixin.java"

echo "FurryClient scaffold created:"
find . -type f -not -path './.git/*' | sort