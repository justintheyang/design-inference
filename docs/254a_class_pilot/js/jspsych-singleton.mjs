import { settings } from "../config.mjs";
let jsPsych = null;

export function getJsPsych() {
  if (!jsPsych) {
    settings.session_data.startExperimentTS = Date.now();
    jsPsych = initJsPsych({
      on_trial_finish: (data) => {
        if (settings.study_metadata.dev_mode) { console.log("trial data", data); }
      },
      show_progress_bar: true,
    });

    jsPsych.data.addProperties({gameID: settings.session_data.gameID});
  }
  return jsPsych;
}