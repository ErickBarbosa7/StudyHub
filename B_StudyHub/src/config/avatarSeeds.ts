// Seeds del estilo "Sprouts" de DiceBear (CC0). Cada seed dibuja siempre la
// misma maceta; estas 23 se eligieron mirando los dibujos para que no haya dos
// parecidos (macetas y plantas distintas, todas con cara amable).
// Los clientes las dibujan en el dispositivo con la librería de DiceBear.
export const AVATAR_SEEDS: readonly string[] = [
  'Aloe',
  'Brote',
  'Cactus',
  'Albahaca',
  'Romero',
  'Lavanda',
  'Hiedra',
  'Bonsai',
  'Orquidea',
  'Margarita',
  'Jazmin',
  'Lirio',
  'Magnolia',
  'Ficus',
  'Manzano',
  'Mora',
  'Higo',
  'Pimienta',
  'Garbanzo',
  'brote-015',
  'brote-024',
  'brote-031',
  'brote-186',
];

// Una seed libre de la lista (al azar entre las libres). Si ya se usaron todas,
// el id del usuario, que es único, hace de seed.
export function pickAvatarSeed(
  usedSeeds: ReadonlySet<string>,
  userId: string,
): string {
  const free = AVATAR_SEEDS.filter((seed) => !usedSeeds.has(seed));
  if (free.length === 0) return userId;
  return free[Math.floor(Math.random() * free.length)] ?? userId;
}
