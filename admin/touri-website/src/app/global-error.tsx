"use client";

export default function GlobalError({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html lang="ar" dir="rtl">
      <body className="flex min-h-screen items-center justify-center bg-[#071512] p-6 text-white">
        <div className="max-w-md text-center">
          <h1 className="text-3xl font-bold">حدث خطأ</h1>
          <p className="mt-3 text-white/70">Something went wrong.</p>
          <button
            type="button"
            onClick={reset}
            className="mt-6 rounded-full bg-[#1f6f5f] px-5 py-3 font-bold"
          >
            Retry
          </button>
        </div>
      </body>
    </html>
  );
}
