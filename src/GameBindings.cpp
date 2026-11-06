#include "GameBindings.hpp"

#include <ampersand/core/ecs/EventQueue.hpp>
#include <ampersand/core/resources/Clock.hpp>
#include <ampersand/core/resources/Stats.hpp>
#include <ampersand/physics/resources/Collisions.hpp>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <utility>
#include <vector>

namespace td {

namespace ecs = ampersand::core::ecs;
using ampersand::core::Clock;
using ampersand::core::Stats;
using ampersand::scripting::ScriptError;
using nlohmann::json;

namespace {

/** @brief JSON as Lua values: objects and arrays become tables. */
sol::object toLua(sol::state_view lua, const json& value) {
    if (value.is_object() || value.is_array()) {
        sol::table table = lua.create_table();
        int index = 1;
        for (const auto& item : value.items()) {
            if (value.is_object()) {
                table[item.key()] = toLua(lua, item.value());
            } else {
                table[index++] = toLua(lua, item.value());
            }
        }
        return table;
    }
    if (value.is_string()) {
        return sol::make_object(lua, value.get<std::string>());
    }
    if (value.is_boolean()) {
        return sol::make_object(lua, value.get<bool>());
    }
    if (value.is_number_integer()) {
        return sol::make_object(lua, value.get<std::int64_t>());
    }
    if (value.is_number()) {
        return sol::make_object(lua, value.get<double>());
    }
    return sol::make_object(lua, sol::lua_nil);
}

/** @brief gameRoot of the configuration, as the engine reads it. */
std::string readGameRoot(const std::string& config) {
    std::ifstream file(config);
    if (!file) {
        throw std::runtime_error("Cannot open configuration '" + config + "'");
    }
    return json::parse(file).value("gameRoot", std::string{});
}

void bindProps(sol::state& lua, ecs::World& world) {
    lua.set_function("getProps",
                     [&world](ecs::Entity entity, sol::this_state state) {
                         return toLua(state, world.get<Props>(entity).data);
                     });
    lua.set_function("hasProps", [&world](ecs::Entity entity) {
        return world.has<Props>(entity);
    });
}

void bindResources(sol::state& lua, ecs::World& world) {
    lua.new_usertype<Clock>(
        "Clock", sol::no_constructor, "dt", sol::readonly(&Clock::dt),
        "elapsed", sol::readonly(&Clock::elapsed), "timeScale",
        sol::property(
            [&world](const Clock&) {
                return world.getResource<TimeScale>().value;
            },
            [&world](Clock&, float scale) {
                if (!std::isfinite(scale) || scale < 0.0F) {
                    throw std::invalid_argument(
                        "timeScale must be finite and not negative");
                }
                world.getResource<TimeScale>().value = scale;
            }));
    lua.set_function("getClock", [&world]() -> Clock& {
        return world.getResource<Clock>();
    });
    lua.new_usertype<Stats>(
        "Stats", sol::no_constructor, "frameMs",
        sol::readonly(&Stats::frameMs), "updateMs",
        sol::readonly(&Stats::updateMs), "fps", sol::readonly(&Stats::fps),
        "entities", sol::readonly(&Stats::entities), "history",
        [](const Stats& stats) { return sol::as_table(stats.history); },
        "value",
        [](const Stats& stats, const std::string& name) {
            const auto found = stats.values.find(name);
            return found == stats.values.end() ? 0.0F : found->second;
        },
        "setValue", [](Stats& stats, const std::string& name, float value) {
            stats.values[name] = value;
        });
    lua.set_function("getStats", [&world]() -> Stats& {
        return world.getResource<Stats>();
    });
    lua.set_function("getCollisions", [&world](ecs::Entity entity) {
        std::vector<ecs::Entity> touching;
        for (const auto& [first, second] :
             world.getResource<ampersand::physics::Collisions>().pairs) {
            if (first == entity) {
                touching.push_back(second);
            } else if (second == entity) {
                touching.push_back(first);
            }
        }
        return sol::as_table(std::move(touching));
    });
}

/** @brief require finds gameRoot/scripts/<name>.lua (the dots of the name
 * being folders) and never loads native code. */
void bindModules(sol::state& lua, const std::string& gameRoot) {
    lua.open_libraries(sol::lib::package);
    lua["package"]["path"] =
        (std::filesystem::path(gameRoot) / "scripts" / "?.lua").string();
    lua["package"]["cpath"] = "";
    lua["package"]["loadlib"] = sol::lua_nil;
}

}  // namespace

void ScriptErrorLog::update(ecs::World& world) {
    for (const auto& error :
         world.getResource<ecs::EventQueue<ScriptError>>().read()) {
        std::cerr << "[script] " << error.message << '\n';
    }
}

void registerComponents(ampersand::scene::SceneManager& scenes) {
    scenes.registerComponent(
        "Props", [](ecs::World& world, ecs::Entity entity, const json& data) {
            world.add(entity, Props{.data = data});
        });
}

void bindScripting(ampersand::scripting::ScriptingSystem& scripting,
                   ecs::Scheduler& scheduler, ecs::World& world,
                   const ampersand::scene::SceneManager& scenes,
                   const std::string& config) {
    world.addResource<TimeScale>();
    scheduler.addEventQueue<ScriptError>();
    sol::state& lua = scripting.lua();
    lua.set_function("getCurrentScene",
                     [&scenes] { return scenes.getCurrentScene(); });
    bindProps(lua, world);
    bindResources(lua, world);
    bindModules(lua, readGameRoot(config));
}

}  // namespace td
