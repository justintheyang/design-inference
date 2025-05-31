import { settings } from "../config.mjs";
let jsPsych = null;

export function getJsPsych() {
  if (!jsPsych) {
    jsPsych = initJsPsych({
      on_start: () => {
        settings.session_data.startExperimentTS = Date.now();
      },
      on_trial_finish: (data) => {
        console.log("trial data", data);
      },
      show_progress_bar: true,
    });
  }
  return jsPsych;
}