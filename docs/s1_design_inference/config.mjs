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

// Parse URL parameters
function getUrlParameter(name) {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get(name);
}

// Get condition from URL parameter (0=cooks, 1=dish)
function getConditionFromUrl() {
  const conditionParam = getUrlParameter('condition');
  if (conditionParam === '0') {
    return 'cooks';
  } else if (conditionParam === '1') {
    return 'dish';
  } else {
    // Default to cooks if no parameter or invalid parameter
    return 'cooks';
  }
}

export let settings = {
  study_metadata: {
    project: "design_inference",
    experiment: "s1_design_inference",
    datapipe_experiment_id: "e7h3xs0D9Mhj",
    iteration_name: "dev",
    dev_mode: true,
    condition: getConditionFromUrl(),
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
