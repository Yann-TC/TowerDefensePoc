#pragma once

// What the game adds on top of the engine, through its public API only
// (registerComponent, ScriptingSystem::lua, addEventQueue): the Props
// component and the Lua functions the scripts use that the engine does not
// bind.
#include <ampersand/core/ecs/ISystem.hpp>
#include <ampersand/core/ecs/Scheduler.hpp>
#include <ampersand/core/ecs/World.hpp>
#include <ampersand/scene/resources/SceneManager.hpp>
#include <ampersand/scripting/systems/ScriptingSystem.hpp>
#include <nlohmann/json.hpp>
#include <string>

namespace td {

/**
 * @brief Free JSON data of an entity, read by its scripts with getProps:
 * "Props": {"health": 50, "speed": 80}. A scene overriding the Props of a
 * prefab merges them field by field (merge of the components by the engine).
 */
struct Props {
    nlohmann::json data;
};

/**
 * @brief Speed of the time, set by the scripts (getClock().timeScale): 0
 * pauses, 2 runs twice as fast. The loop multiplies the dt given to the
 * Scheduler by it, so the Stats keep the real times.
 */
struct TimeScale {
    float value{1.0F};
};

/** @brief Prints the errors of the scripts on the standard error (the engine
 * only sends them to the EventQueue<ScriptError>). Runs after the
 * ScriptingSystem. */
class ScriptErrorLog final : public ampersand::core::ecs::ISystem {
public:
    void update(ampersand::core::ecs::World& world) override;
};

/** @brief Registers the Props component in the SceneManager. */
void registerComponents(ampersand::scene::SceneManager& scenes);

/**
 * @brief Adds the TimeScale and EventQueue<ScriptError> resources, and gives
 * the scripts getProps, hasProps, getCurrentScene, getClock, getStats,
 * getCollisions and require of the modules gameRoot/scripts/<name>.lua.
 *
 * @param config Configuration file, read for its gameRoot.
 */
void bindScripting(ampersand::scripting::ScriptingSystem& scripting,
                   ampersand::core::ecs::Scheduler& scheduler,
                   ampersand::core::ecs::World& world,
                   const ampersand::scene::SceneManager& scenes,
                   const std::string& config);

}  // namespace td
