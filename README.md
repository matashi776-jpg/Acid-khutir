# Mausoleum 2.2: Lanchyn (Web Build)

A lightweight TypeScript + Vite action-defense prototype built for GitHub Pages.

## Gameplay
- Protect the mausoleum core in the center.
- Move with **WASD** or **Arrow keys**.
- Attack with **Left Click** or **Space** in the aimed direction.
- Survive escalating waves; enemies that reach you or the core reduce wall health.
- Press **R** after game over to restart.

## Development
```bash
npm install
npm run dev
```

## Production build
```bash
npm run build
npm run preview
```

## GitHub Pages
The Vite base path is configured for repository subpath deployment:
`/mausoleum-2.2-lanchyn/`

The GitHub Actions workflow builds and deploys the `dist/` output directory.
