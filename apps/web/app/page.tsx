export default function HomePage() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center bg-gray-950 text-white">
      <h1 className="text-6xl font-bold mb-4">JobCompass</h1>

      <p className="text-xl text-gray-400 mb-10">
        AI-помощник для поиска работы
      </p>

      <button className="rounded-xl bg-blue-600 px-6 py-3 text-lg font-medium hover:bg-blue-500 transition">
        Начать
      </button>
    </main>
  );
}
