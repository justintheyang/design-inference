function UUID() {
  const baseName =
    Math.floor(Math.random() * 10) +
    "" +
    Math.floor(Math.random() * 10) +
    "" +
    Math.floor(Math.random() * 10) +
    "" +
    Math.floor(Math.random() * 10);
  const template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx";
  const id =
    baseName +
    "-" +
    template.replace(/[xy]/g, function (c) {
      let r = (Math.random() * 16) | 0,
        v = c == "x" ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  return id;
}

const gameID = UUID();

export let settings = {
  study_metadata: {
    project: "design-inference",
    experiment: "exp1",
    datapipe_experiment_id: "3hpe3tXu2deq",
    iteration_name: "pilot_local",
    dev_mode: false,
    condition: null, // we have no between-subjects condition
  },
  session_data: {
    gameID: gameID,
    startExperimentTS: undefined,
    endExperimentTS: undefined,
    comprehensionAttempts: 0,
  },
  experiment_params: {
    time_estimate: 10, // in minutes
  },
};
