import styles from "./features.module.css";

const Feature = ({ text }: { text: string }) => (
  <div className={styles.feature}>
    <h4>{text}</h4>
  </div>
);

const FEATURES = [
  "🪛 Straightforward setup",
  "🌐 Universal compability",
  "🕊 Subscriptions capable",
  "👾 GraphQL schema agnostic",
  "🚀 Wide range of features",
  "🏅 GraphQL spec-compliant",
];

const FEATURES_SM = [
  "🪛 Straightforward",
  "🌐 Universal",
  "🕊 Subscriptions",
  "👾 Schema agnostic",
  "🚀 Powerful",
  "🏅 Spec-compliant",
];

export default () => {
  return (
    <>
      <div className="hidden md:block mx-auto max-w-full w-[880px] text-center px-4 mb-10">
        <div className={styles.features}>
          {FEATURES.map((feature) => (
            <Feature text={feature} />
          ))}
        </div>
      </div>
      <div className="md:hidden mx-auto max-w-full w-[880px] text-center px-4 mb-10">
        <div className={styles.features}>
          {FEATURES_SM.map((feature) => (
            <Feature text={feature} />
          ))}
        </div>
      </div>
    </>
  );
};
