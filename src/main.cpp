// The game is data and Lua scripts run by the engine: this file only opens
// the window, adds the systems and runs the loop. GameBindings adds what the
// scripts need on top of the engine (Props, getProps, require...).
#include "GameBindings.hpp"

#include <ampersand/audio/systems/AudioSystem.hpp>
#include <ampersand/core/ecs/Scheduler.hpp>
#include <ampersand/core/ecs/World.hpp>
#include <ampersand/core/time/FrameTimer.hpp>
#include <ampersand/input/Event.hpp>
#include <ampersand/input/systems/InputSystem.hpp>
#include <ampersand/physics/resources/Collisions.hpp>
#include <ampersand/physics/systems/CollisionSystem.hpp>
#include <ampersand/physics/systems/MovementSystem.hpp>
#include <ampersand/render/Event.hpp>
#include <ampersand/render/resources/Renderer.hpp>
#include <ampersand/render/systems/AnimationSystem.hpp>
#include <ampersand/render/systems/RenderSystem.hpp>
#include <ampersand/scene/resources/SceneManager.hpp>
#include <ampersand/scripting/systems/ScriptingSystem.hpp>
#include <cstdint>
#include <exception>
#include <iostream>
#include <optional>
#include <string>
#include <type_traits>
#include <variant>

namespace ecs = ampersand::core::ecs;
namespace input = ampersand::input;
namespace render = ampersand::render;

constexpr const char* kDefaultConfig = "world/config.json";

// Entities the World can hold: more than the engine default (10000), for the
// thousands of enemies of the Stress Test (2 or 3 entities each).
constexpr std::uint32_t kMaxEntities = 50000;

/** @brief Next input event of the window. Closing the window ends the game. */
std::optional<input::Event> pollWindow(ecs::World& world) {
    auto& window = world.getResource<render::Renderer>();
    while (const auto event = window.renderer.pollEvent()) {
        const auto forwarded = std::visit(
            [&window](const auto& value) -> std::optional<input::Event> {
                using Type = std::decay_t<decltype(value)>;
                if constexpr (std::is_same_v<Type, render::Closed>) {
                    window.isOpen = false;
                } else if constexpr (std::is_constructible_v<input::Event,
                                                             Type>) {
                    return value;
                }
                return std::nullopt;
            },
            *event);
        if (forwarded) {
            return forwarded;
        }
    }
    return std::nullopt;
}

/** @brief The systems of the game, in the order they run each frame. The
 * scripts get the functions of the SceneManager (instantiate, loadScene) and
 * of the game (getProps, require...). */
void addSystems(ecs::Scheduler& scheduler, ecs::World& world,
                ampersand::scene::SceneManager& scenes,
                const std::string& config) {
    scheduler.add<input::InputSystem>(pollWindow);
    auto& scripting = scheduler.add<ampersand::scripting::ScriptingSystem>();
    scenes.bindScripting(scripting, world);
    td::bindScripting(scripting, scheduler, world, scenes, config);
    scheduler.add<td::ScriptErrorLog>();
    scheduler.add<ampersand::physics::MovementSystem>();
    // After the scripts moved the pointer: what it touches is read by the
    // scripts on the next frame (see scripts/pointer.lua).
    scheduler.add<ampersand::physics::CollisionSystem>();
    scheduler.add<render::AnimationSystem>();
    scheduler.add<ampersand::audio::AudioSystem>();
    scheduler.add<render::RenderSystem>();
}

void run(const std::string& config) {
    ecs::World world(kMaxEntities);
    world.addResource<ampersand::physics::Collisions>();
    ampersand::scene::SceneManager scenes;
    td::registerComponents(scenes);
    ecs::Scheduler scheduler(world);
    addSystems(scheduler, world, scenes, config);
    scenes.loadConfig(world, config);

    ampersand::core::FrameTimer timer;
    while (world.getResource<render::Renderer>().isOpen) {
        // Scaled here: the Clock of the engine has no time scale.
        scheduler.update(timer.tick() *
                         world.getResource<td::TimeScale>().value);
    }
}

int main(int argc, char* argv[]) {
    try {
        run(argc > 1 ? argv[1] : kDefaultConfig);
    } catch (const std::exception& error) {
        std::cerr << "tower_defense: " << error.what() << '\n';
        return 1;
    }
    return 0;
}
