#!/bin/bash

# Setup Lovable Architect Project (V4.2)
# Usage: ./setup-lovable-project.sh <project-name>

PROJECT_NAME=$1

if [ -z "$PROJECT_NAME" ]; then
  echo "Usage: ./setup-lovable-project.sh <project-name>"
  exit 1
fi

echo "🏗️  Building Lovable Architect Foundation V4.2: $PROJECT_NAME..."

# 1. Create Vite project
npm create vite@latest "$PROJECT_NAME" -- --template react-ts
cd "$PROJECT_NAME" || exit

# 2. Install Styling & UI
echo "🎨 Installing Styling & UI..."
npm install -D tailwindcss postcss autoprefixer tailwindcss-animate
npx tailwindcss init -p
npm install lucide-react framer-motion sonner clsx tailwind-merge

# 3. Install Logic & Backend
echo "📦 Installing Supabase & Logic..."
npm install @supabase/supabase-js @tanstack/react-query zod

# 4. Install Testing Suite
echo "🧪 Installing Vitest & Testing Library..."
npm install -D vitest @vitejs/plugin-react @testing-library/react \
  @testing-library/user-event @testing-library/dom @testing-library/jest-dom \
  jsdom

# 5. Install Quality Tools
echo "🧹 Installing ESLint & Prettier..."
npm install -D prettier eslint-config-prettier eslint-plugin-react

# 6. Configure Package Scripts (V4.2 Fix)
echo "📜 Configuring NPM scripts..."
npm pkg set scripts.test="vitest"
npm pkg set scripts.test:ui="vitest --ui"
npm pkg set scripts.test:coverage="vitest run --coverage"

# 7. Advanced Folder Structure
echo "📁 Creating Folder Structure..."
mkdir -p src/features src/services src/hooks src/lib src/components/ui src/test src/pages

# 8. Initialize PROJECT.md (Persistent Memory)
cat > PROJECT.md <<EOF
# Project: $PROJECT_NAME

## Architecture
- Framework: React + Vite
- Language: TypeScript (Strict Mode)
- Path Aliases: @/* -> src/*
- Styling: Tailwind CSS + Shadcn/UI
- Backend: Supabase
- Testing: Vitest + React Testing Library

## Status
- [x] Initial Scaffolding V4.2
- [ ] Setup Routing
- [ ] Feature: Authentication

## Decisions
- Used feature-based directory structure for scalability.
- Enforced Vitest for all business logic and complex components.
- Integrated path aliases (@/) for cleaner imports.
EOF

# 9. Configure Prettier (V4.2 Fix)
cat > .prettierrc <<EOF
{
  "semi": false,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5"
}
EOF

# 10. Configure Vitest
cat > vitest.config.ts <<EOF
import path from "path"
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test/setup.ts',
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
})
EOF

mkdir -p src/test
cat > src/test/setup.ts <<EOF
import '@testing-library/jest-dom'
EOF

# 11. Configure Vite (with Aliases)
cat > vite.config.ts <<EOF
import path from "path"
import react from "@vitejs/plugin-react"
import { defineConfig } from "vite"

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
})
EOF

# 12. Configure TypeScript (Aliases & Strict Mode - V4.2 Fix)
cat > tsconfig.json <<EOF
{
  "compilerOptions": {
    "target": "ESNext",
    "useDefineForClassFields": true,
    "lib": ["DOM", "DOM.Iterable", "ESNext"],
    "allowJs": false,
    "skipLibCheck": true,
    "esModuleInterop": false,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

# 13. Configure Shadcn
cat > components.json <<EOF
{
  "\$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.js",
    "css": "src/index.css",
    "baseColor": "slate",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils"
  }
}
EOF

cat > src/lib/utils.ts <<EOF
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
EOF

# 14. Configure Tailwind
cat > tailwind.config.js <<EOF
/** @type {import('tailwindcss').Config} */
export default {
    darkMode: ["class"],
    content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
  	extend: {
  		borderRadius: {
  			lg: 'var(--radius)',
  			md: 'calc(var(--radius) - 2px)',
  			sm: 'calc(var(--radius) - 4px)'
  		},
  		colors: {
  			background: 'hsl(var(--background))',
  			foreground: 'hsl(var(--foreground))',
  			primary: {
  				DEFAULT: 'hsl(var(--primary))',
  				foreground: 'hsl(var(--primary-foreground))'
  			},
  			border: 'hsl(var(--border))',
  			input: 'hsl(var(--input))',
  			ring: 'hsl(var(--ring))',
  		}
  	}
  },
  plugins: [require("tailwindcss-animate")],
}
EOF

# 15. Create base CSS
cat > src/index.css <<EOF
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --primary: 221.2 83.2% 53.3%;
    --primary-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --radius: 0.75rem;
  }
}
@layer base {
  * { @apply border-border; }
  body { @apply bg-background text-foreground antialiased font-sans; }
}
EOF

echo "✅ Lovable Architect V4.2 Ready!"
echo "🚀 Next steps: npm install && npm run dev"
echo "📝 Remember to maintain PROJECT.md for every session."
