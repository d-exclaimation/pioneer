export default () => {
  return (
    <div className="flex flex-row items-center justify-center w-full">
      <img className="w-32 hidden md:block md:w-40" src="/pioneer.png" />
      <div className="flex flex-col items-center md:items-start justify-center">
        <h1 className="font-extrabold text-4xl md:text-5xl mt-8">Pioneer</h1>
        <span className="text-lg my-5 text-gray-600 md:!text-2xl">
          GraphQL server for Swift
        </span>
      </div>
    </div>
  );
};
