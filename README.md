# Unity Smart Invoker (Mono & IL2CPP)

**Author:** Veni  
**Discord:** ._.veni._.

Lua tool for **Cheat Engine** designed to automate the process of finding Class Instances ("this" pointers) and invoking methods in Unity games. It works for both **Mono** and **IL2CPP** backends.

## 🚀 Features

* **Auto-Detection:** Automatically detects if the game is running on Mono or IL2CPP and adjusts accordingly.
* **Smart Hooking (Anti-Crash):** Calculates instruction sizes dynamically to prevent "cutting" instructions in half, ensuring a stable hook.
* **Safe 64-bit Addressing:** Uses absolute addressing logic to prevent memory allocation crashes when jumping to far locations.
* **Method Invoker:** Allows you to call any void or parameterized method (with arguments) directly from the Cheat Table.
* **Clean Output:** Generates named symbols based on the actual class and method names (e.g., `Player_Update`) rather than random dynamic addresses.
* **Argument Support:** Supports passing complex arguments (integers, strings, booleans, etc.) to invoked functions.

## 🛠️ Prerequisites

* [Cheat Engine 7.4+](https://www.cheatengine.org/)
* A target game running on Unity (Mono or IL2CPP).

## 📥 How to Use

1.  **Attach** Cheat Engine to your target game process.
2.  Open the **Lua Engine** in Cheat Engine (`Ctrl+L`).
3.  Load the `VENI_SMART_MONOIL2CPP_INVOKER.lua` script.
4.  Click **Execute**.
5.  Follow the prompts in the dialog box:
    * **Namespace:** The namespace of the class (e.g., `Assembly-CSharp` or leave empty).
    * **Class Name:** The class you want to target (e.g., `PlayerHealth`).
    * **Hook Method:** A method that runs frequently (like `Update` or `FixedUpdate`) to grab the instance.
    * **Invoke Method:** The method you want to call manually (e.g., `Heal` or `AddGold`).
6.  **Enable** the generated "Instance Hook" script in your Cheat Table.
    * *Wait a second for the game to run the hooked code.*
    * You should see the "Instance Address" populate with a valid pointer.
7.  **Click** the generated "INVOKE" script to execute your chosen method.

## ⚙️ How It Works

This tool compiles a JIT hook at the specified method. Instead of using a standard 5-byte jump which can corrupt instructions if not aligned, it scans the assembly to find the safe hook size.

It then injects a "Smart Grabber" that:
1.  Saves the CPU flags (`pushfq`) to preserve game state.
2.  Checks if the instance has already been found to avoid redundant writes (thread safety).
3.  Safe-saves the `RCX` register (which holds the `this` pointer in x64 Unity games) to a global symbol.

## ⚠️ Disclaimer

This tool is for educational purposes only. Use it responsibly in single-player games. I am not responsible for any bans or issues caused by misuse in online environments.
