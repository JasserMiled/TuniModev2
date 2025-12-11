type TabItem<T extends string> = {
  key: T;
  label: string;
  hidden?: boolean;
};

export type TabMenuProps<T extends string> = {
  tabs: TabItem<T>[];
  activeKey: T;
  onChange: (key: T) => void;
  className?: string;
};

export function TabMenu<T extends string>({
  tabs,
  activeKey,
  onChange,
  className = "",
}: TabMenuProps<T>) {
  const visibleTabs = tabs.filter((tab) => !tab.hidden);

  return (
    <div className={`flex border-b ${className}`.trim()}>
      {visibleTabs.map((tab) => (
        <button
          key={tab.key}
          onClick={() => onChange(tab.key)}
          className={`px-6 py-2 font-semibold transition ${
            activeKey === tab.key
              ? "border-b-2 border-blue-600 text-blue-600"
              : "text-gray-500"
          }`}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}

export default TabMenu;
