type SegmentedSearchButtonProps = {
  onSearch: () => void;
  onOpenFilters: () => void;
};

export default function SegmentedSearchButton({
  onSearch,
  onOpenFilters,
}: SegmentedSearchButtonProps) {
  return (
<div className="inline-flex overflow-hidden border border-neutral-200 shadow-sm rounded-lg">

      {/* Zone Filtres */}
      <button
        onClick={onOpenFilters}
        className="flex items-center gap-2 px-12 py-2.5 bg-[#F4F1FF] text-neutral-700 text-sm font-semibold hover:bg-[#EAE6FF] transition"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          className="w-4 h-4 text-blue-600"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2a1 1 0 01-.293.707L15 12.414V19a1 1 0 01-.553.894l-4 2A1 1 0 019 21v-8.586L3.293 6.707A1 1 0 013 6V4z"
          />
        </svg>

        Filtres
      </button>

      {/* Séparateur */}
      <div className="w-px bg-neutral-300" />

      {/* Zone Chercher */}
      <button
        onClick={onSearch}
        className="px-12 py-2.5 bg-blue-600 text-white text-sm font-semibold hover:bg-blue-700 transition"
      >
        Chercher
      </button>
    </div>
  );
}
