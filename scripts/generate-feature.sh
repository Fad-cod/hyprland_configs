#!/bin/bash
# ============================================================
# Lovable Architect V5 — Feature Generator
# Usage: ./scripts/generate-feature.sh <feature-name>
# Example: ./scripts/generate-feature.sh auth
# ============================================================

FEATURE_NAME=$1
FEATURE_DIR="src/features/$FEATURE_NAME"

# ── Validation ───────────────────────────────────────────────
if [ -z "$FEATURE_NAME" ]; then
  echo "❌ Usage: ./scripts/generate-feature.sh <feature-name>"
  exit 1
fi

if [ -d "$FEATURE_DIR" ]; then
  echo "❌ Feature '$FEATURE_NAME' already exists at $FEATURE_DIR"
  exit 1
fi

# ── Capitalisation du nom (ex: auth → Auth) ──────────────────
FEATURE_PASCAL="$(echo "${FEATURE_NAME:0:1}" | tr '[:lower:]' '[:upper:]')${FEATURE_NAME:1}"

echo "🚀 Generating feature: $FEATURE_NAME..."

# ── Structure des dossiers ───────────────────────────────────
mkdir -p "$FEATURE_DIR/components"
mkdir -p "$FEATURE_DIR/hooks"
mkdir -p "$FEATURE_DIR/services"

# ────────────────────────────────────────────────────────────
# 1. COMPOSANT DE BASE + SON TEST
# ────────────────────────────────────────────────────────────
cat > "$FEATURE_DIR/components/${FEATURE_PASCAL}Page.tsx" <<EOF
import { cn } from "@/lib/utils"

interface ${FEATURE_PASCAL}PageProps {
  className?: string
}

export function ${FEATURE_PASCAL}Page({ className }: ${FEATURE_PASCAL}PageProps) {
  return (
    <div className={cn("max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12", className)}>
      <div className="flex flex-col gap-6">
        <div>
          <h1 className="tracking-tight font-bold text-slate-900 text-3xl">
            ${FEATURE_PASCAL}
          </h1>
          <p className="leading-relaxed text-slate-600 mt-2">
            ${FEATURE_PASCAL} feature — à implémenter.
          </p>
        </div>

        <div className="bg-card text-card-foreground rounded-xl border shadow-sm p-6">
          <p className="text-slate-600">Contenu de la feature ${FEATURE_PASCAL}</p>
        </div>
      </div>
    </div>
  )
}
EOF

cat > "$FEATURE_DIR/components/${FEATURE_PASCAL}Page.test.tsx" <<EOF
import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { ${FEATURE_PASCAL}Page } from './${FEATURE_PASCAL}Page'

describe('${FEATURE_PASCAL}Page', () => {
  it('renders the page title', () => {
    render(<${FEATURE_PASCAL}Page />)
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('${FEATURE_PASCAL}')
  })

  it('accepts a custom className', () => {
    const { container } = render(<${FEATURE_PASCAL}Page className="test-class" />)
    expect(container.firstChild).toHaveClass('test-class')
  })
})
EOF

# ────────────────────────────────────────────────────────────
# 2. HOOK MÉTIER + SON TEST
# ────────────────────────────────────────────────────────────
cat > "$FEATURE_DIR/hooks/use${FEATURE_PASCAL}.ts" <<EOF
import { useState, useCallback } from 'react'

interface Use${FEATURE_PASCAL}Return {
  isLoading: boolean
  error: string | null
  data: unknown | null
  fetch${FEATURE_PASCAL}Data: () => Promise<void>
}

export function use${FEATURE_PASCAL}(): Use${FEATURE_PASCAL}Return {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [data, setData] = useState<unknown | null>(null)

  const fetch${FEATURE_PASCAL}Data = useCallback(async () => {
    try {
      setIsLoading(true)
      setError(null)
      // TODO: Intégrer ${FEATURE_PASCAL}Service.getAll()
      setData(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Une erreur est survenue')
    } finally {
      setIsLoading(false)
    }
  }, [])

  return { isLoading, error, data, fetch${FEATURE_PASCAL}Data }
}
EOF

cat > "$FEATURE_DIR/hooks/use${FEATURE_PASCAL}.test.ts" <<EOF
import { renderHook, act } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { use${FEATURE_PASCAL} } from './use${FEATURE_PASCAL}'

describe('use${FEATURE_PASCAL}', () => {
  it('initializes with correct default state', () => {
    const { result } = renderHook(() => use${FEATURE_PASCAL}())

    expect(result.current.isLoading).toBe(false)
    expect(result.current.error).toBeNull()
    expect(result.current.data).toBeNull()
  })

  it('sets isLoading to true then false during fetch', async () => {
    const { result } = renderHook(() => use${FEATURE_PASCAL}())

    await act(async () => {
      await result.current.fetch${FEATURE_PASCAL}Data()
    })

    expect(result.current.isLoading).toBe(false)
  })
})
EOF

# ────────────────────────────────────────────────────────────
# 3. SERVICE SUPABASE
# ────────────────────────────────────────────────────────────
cat > "$FEATURE_DIR/services/${FEATURE_NAME}.service.ts" <<EOF
// TODO: Remplacer par le vrai client Supabase
// import { supabase } from '@/lib/supabase'

export interface ${FEATURE_PASCAL}Item {
  id: string
  created_at: string
  // TODO: Ajouter les champs de la table Supabase
}

export const ${FEATURE_PASCAL}Service = {
  /**
   * Récupère tous les éléments de la table ${FEATURE_NAME}
   * RLS Policy requise: SELECT pour les utilisateurs authentifiés
   */
  async getAll(): Promise<${FEATURE_PASCAL}Item[]> {
    // const { data, error } = await supabase.from('${FEATURE_NAME}').select('*')
    // if (error) throw new Error(error.message)
    // return data
    throw new Error('${FEATURE_PASCAL}Service.getAll() non implémenté')
  },

  /**
   * Crée un nouvel élément
   * RLS Policy requise: INSERT pour les utilisateurs authentifiés
   */
  async create(payload: Omit<${FEATURE_PASCAL}Item, 'id' | 'created_at'>): Promise<${FEATURE_PASCAL}Item> {
    // const { data, error } = await supabase.from('${FEATURE_NAME}').insert(payload).select().single()
    // if (error) throw new Error(error.message)
    // return data
    throw new Error('${FEATURE_PASCAL}Service.create() non implémenté')
  },

  /**
   * Supprime un élément par ID
   * RLS Policy requise: DELETE pour le propriétaire uniquement
   */
  async delete(id: string): Promise<void> {
    // const { error } = await supabase.from('${FEATURE_NAME}').delete().eq('id', id)
    // if (error) throw new Error(error.message)
    throw new Error('${FEATURE_PASCAL}Service.delete() non implémenté')
  },
}

/*
 * ── Supabase RLS Policies suggérées ──────────────────────────
 *
 * -- Lecture : utilisateurs authentifiés seulement
 * CREATE POLICY "select_${FEATURE_NAME}" ON ${FEATURE_NAME}
 *   FOR SELECT USING (auth.uid() IS NOT NULL);
 *
 * -- Insertion : utilisateurs authentifiés seulement
 * CREATE POLICY "insert_${FEATURE_NAME}" ON ${FEATURE_NAME}
 *   FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
 *
 * -- Suppression : propriétaire uniquement
 * CREATE POLICY "delete_own_${FEATURE_NAME}" ON ${FEATURE_NAME}
 *   FOR DELETE USING (auth.uid() = user_id);
 */
EOF

# ────────────────────────────────────────────────────────────
# 4. INDEX D'EXPORT (barrel file)
# ────────────────────────────────────────────────────────────
cat > "$FEATURE_DIR/index.ts" <<EOF
// Feature: ${FEATURE_PASCAL}
// Point d'entrée unique — importer depuis ici uniquement
export { ${FEATURE_PASCAL}Page } from './components/${FEATURE_PASCAL}Page'
export { use${FEATURE_PASCAL} } from './hooks/use${FEATURE_PASCAL}'
export { ${FEATURE_PASCAL}Service } from './services/${FEATURE_NAME}.service'
export type { ${FEATURE_PASCAL}Item } from './services/${FEATURE_NAME}.service'
EOF

# ────────────────────────────────────────────────────────────
# 5. MISE À JOUR PROJECT.MD
# ────────────────────────────────────────────────────────────
if [ -f "PROJECT.md" ]; then
  echo "" >> PROJECT.md
  echo "## Feature: ${FEATURE_PASCAL} (généré le $(date '+%Y-%m-%d'))" >> PROJECT.md
  echo "- [ ] Implémenter ${FEATURE_PASCAL}Service (Supabase)" >> PROJECT.md
  echo "- [ ] Implémenter use${FEATURE_PASCAL} hook" >> PROJECT.md
  echo "- [ ] Construire les composants UI" >> PROJECT.md
  echo "- [ ] Ajouter les RLS policies dans Supabase" >> PROJECT.md
  echo "✅ PROJECT.md mis à jour"
fi

# ────────────────────────────────────────────────────────────
# RÉSUMÉ
# ────────────────────────────────────────────────────────────
echo ""
echo "✅ Feature '${FEATURE_NAME}' générée avec succès !"
echo ""
echo "📁 Structure créée :"
echo "   $FEATURE_DIR/"
echo "   ├── components/${FEATURE_PASCAL}Page.tsx"
echo "   ├── components/${FEATURE_PASCAL}Page.test.tsx"
echo "   ├── hooks/use${FEATURE_PASCAL}.ts"
echo "   ├── hooks/use${FEATURE_PASCAL}.test.ts"
echo "   ├── services/${FEATURE_NAME}.service.ts  (+ RLS policies)"
echo "   └── index.ts  (barrel export)"
echo ""
echo "🧪 Lance les tests : npm test"
echo "📋 Checklist PROJECT.md mise à jour"
echo ""
echo "Prochaines étapes :"
echo "  1. Connecte le client Supabase dans src/lib/supabase.ts"
echo "  2. Implémente ${FEATURE_PASCAL}Service.getAll() / .create() / .delete()"
echo "  3. Branche use${FEATURE_PASCAL} sur le service"
echo "  4. Applique les RLS policies dans ton dashboard Supabase"
