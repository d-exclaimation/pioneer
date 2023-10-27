type Props = {
  text: string;
  variant: "primary" | "secondary" | "success" | "danger" | "warning";
};

export default ({ text, variant }: Props) => {
  const color = (() => {
    switch (variant) {
      case "primary":
        return "bg-blue-100 text-blue-800";
      case "secondary":
        return "bg-indigo-100 text-indigo-800";
      case "success":
        return "bg-emerald-100 text-emerald-800";
      case "danger":
        return "bg-red-100 text-red-800";
      case "warning":
        return "bg-amber-100 text-amber-800";
    }
  })();
  return (
    <span
      className={`${color} inline-flex items-center justify-center text-center px-2 py-0.5 text-xs rounded-md w-fit`}
    >
      {text}
    </span>
  );
};
