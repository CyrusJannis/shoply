# Shoply App - Product Requirements Document

## Original Problem Statement
1. Make shopping history perfect - improve design with card-based list selection, ensure it works and syncs across devices for people in the same list
2. Apply iOS 26 liquid glass design to all buttons, dropdowns, and menus across the app
3. Add an AI chatbot section with Avo mascot that can do everything the user can do in the app

## User Personas
- **Primary**: Users who want to manage shopping lists collaboratively with family/friends
- **Secondary**: Recipe enthusiasts who want ingredient suggestions and meal planning help

## Core Requirements (Static)
- Shopping list management with real-time sync
- Recipe discovery and search
- Shopping history tracking
- AI-powered assistant (Avo) for hands-free interaction

## What's Been Implemented (Jan 2026)

### Shopping History Improvements
- ✅ Card-based list selection (horizontal scrollable cards)
- ✅ Enhanced design with liquid glass styling
- ✅ Shared history across devices via Supabase (already implemented)
- ✅ Individual item add buttons with visual feedback
- ✅ Add all items functionality

### iOS 26 Liquid Glass Design
- ✅ Created `/app/lib/core/widgets/liquid_glass_widgets.dart` with:
  - LiquidGlassButton (primary/secondary/destructive variants)
  - LiquidGlassIconButton
  - LiquidGlassCard
  - LiquidGlassDropdown
  - LiquidGlassChip
  - LiquidGlassTextField
- ✅ Existing liquid glass button system in `/app/lib/presentation/widgets/common/liquid_glass_button.dart`

### Avo AI Chatbot
- ✅ Created `/app/lib/data/services/avo_assistant_service.dart`:
  - Uses Gemini 2.0 Flash Lite (cheapest model)
  - Friendly Avo personality
  - Can add items to lists, search recipes, analyze lists
  - Context-aware responses using app data
- ✅ Created `/app/lib/presentation/screens/ai/avo_chat_screen.dart`:
  - Full chat UI with message bubbles
  - Avo mascot with expressions
  - Quick actions menu
  - Recipe results display
- ✅ Added navigation tab (4 tabs: Home, Avo, Recipes, Profile)
- ✅ Added translations for English and German

## Architecture
- **Frontend**: Flutter with Riverpod state management
- **Backend**: Supabase (PostgreSQL, Auth, Realtime)
- **AI**: Google Gemini API (gemini-2.0-flash-lite)
- **Design System**: iOS 26 Liquid Glass pattern

## Prioritized Backlog

### P0 (Critical)
- None currently

### P1 (High Priority)
- Test Avo chatbot with real Gemini API key
- Add more quick actions to Avo

### P2 (Medium Priority)
- Add voice input to Avo chat
- Implement Avo conversation history persistence
- Add more liquid glass styling to remaining screens

## Next Tasks
1. User needs to ensure env.dart is properly configured with Gemini API key
2. Test Avo chatbot functionality end-to-end
3. Add more conversational capabilities to Avo
