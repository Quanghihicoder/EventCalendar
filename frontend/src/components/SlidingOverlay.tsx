import { type ReactNode } from "react";

interface SlidingOverlayProps {
  isOpen: boolean;
  onClose: () => void;
  width?: string; // e.g., "w-80", "w-96"
  children: ReactNode;
  title?: string;
}

export default function SlidingOverlay({
  isOpen,
  onClose,
  children,
  title,
}: SlidingOverlayProps) {
  return (
    <>
      {/* Background overlay */}
      <div
        className={`fixed inset-0 bg-black bg-opacity-40 transition-opacity duration-300 ${
          isOpen
            ? "opacity-100 pointer-events-auto"
            : "opacity-0 pointer-events-none"
        }`}
        onClick={onClose}
      ></div>

      {/* Fullscreen sliding panel */}
      <div
        className={`fixed inset-0 bg-white transform transition-transform duration-300 ${
          isOpen ? "translate-y-0" : "-translate-y-full"
        } flex flex-col`}
      >
        {/* Header */}
        {title && (
          <div className="p-4 flex justify-between items-center border-b">
            <h2 className="text-xl font-semibold">{title}</h2>
            <button
              onClick={onClose}
              className="text-gray-500 hover:text-gray-700 text-2xl font-bold"
            >
              ✕
            </button>
          </div>
        )}

        {/* Content */}
        <div className="p-4 flex-1 overflow-auto">{children}</div>
      </div>
    </>
  );
}
