# Arcana Ascension

A tactical card game built with Godot 4.5, utilizing a standard 78-card Tarot deck.

## 🃏 Game Overview
Arcana Ascension is a high-stakes tactical game played on a 5x5 spatial grid. Players compete to saturate rows and columns with their suits, trigger powerful Major Arcana laws, and maximize their Soul Score while protecting their collection's integrity.

## ✨ Core Features
- **Tactical Grid Combat:** 5x5 grid with "Locked Axis" movement rules.
- **World Flip Mechanics:** Randomized Trump suits and Ace orientations (High/Low) every match.
- **Suit Saturation:** Dominate lines by playing specific suits to gain scoring advantages.
- **Major Arcana Effects:** 22 unique global laws that alter the board, scores, and rules when flipped.
- **Meta-Progression:** Track your progress through a 10-match gauntlet.
- **Collection Management:** Fuse duplicates to upgrade card tiers and manage "Corner Integrity" to prevent demotion.
- **3D Perspective UI:** A beautifully rendered tilted board with a dynamic, fanned card hand.

## 🛠️ Tech Stack
- **Engine:** Godot 4.5 (Forward+ Renderer)
- **Language:** GDScript
- **Architecture:** Modular manager-based design (Deck, Match, Perimeter, Collection, Gauntlet).

## 🚀 Getting Started
1. Clone the repository.
2. Open the project in **Godot 4.5**.
3. Run the `MainMenu.tscn` to start your gauntlet!

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
