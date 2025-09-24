import { loadingSequence } from "./loading-sequence.mjs";
import { instructionSequence } from "./instructions.mjs";
import { exitSurveySequence } from "./exit-sequence.mjs";
import { getJsPsych } from "./jspsych-singleton.mjs";
import { settings } from "../config.mjs";

// Load trials metadata and experiment assets
let trialsMetadataJson = [];
let experimentAssetsJson = [];

async function loadTrialsMetadata() {
  const response = await fetch('assets/trials_metadata.json');
  trialsMetadataJson = await response.json();
}

async function loadExperimentAssets() {
  const response = await fetch('assets/experiment_assets.json');
  experimentAssetsJson = await response.json();
}

export async function setupGame() {
  const jsPsych = getJsPsych();

  // Load metadata and assets
  await Promise.all([
    loadTrialsMetadata(),
    loadExperimentAssets()
  ]);

  // Combine static assets with trial stimuli
  const experiment_assets = [
    ...experimentAssetsJson,
    ...trialsMetadataJson.map(trial => `assets/stims/${trial.trial_id}.png`)
  ];

  // Select trials based on condition using JSON metadata
  const condition = settings.study_metadata.condition;
  const relevantTrials = trialsMetadataJson.filter(trial => trial.trial_type === condition);
  const selected_stims = relevantTrials.map(trial => `assets/stims/${trial.trial_id}.png`);
  
  // Set up question based on condition
  let question;
  if (condition === "cooks") {
    question = [
      {
        prompt: "How many cooks was this kitchen made for?",
        name: "intent_agents",
        min_label: "<img src='assets/trial/1_cook.png' style='height: 60px;'>",
        max_label: "<img src='assets/trial/2_cooks.png' style='height: 60px;'>",
      }
    ];
  } else if (condition === "dish") {
    question = [
      {
        prompt: "Which dish was this kitchen made for?",
        name: "intent_recipe",
        min_label: "<img src='assets/trial/tomato_lettuce.png' style='height: 60px;'>",
        max_label: "<img src='assets/trial/onion_lettuce.png' style='height: 60px;'>",
      }
    ];
  }

  const inference_trials = _.map(_.shuffle(selected_stims), (stim, i) => {
    return {
      type: jsPsychSurveySlider,
      preamble: `<img src="${stim}" style="height: 450px;">`,
      questions: question,
      require_movement: true,
      slider_width: 800,
      post_trial_gap: 500,
      on_start: () => {
        jsPsych.progressBar.message = `Kitchen ${i + 1} of ${selected_stims.length}`;
        jsPsych.progressBar.update();
      },
      on_finish: () => {
        jsPsych.progressBar.progress = Math.min(jsPsych.progressBar.progress + 1 / selected_stims.length, 1);
      }
    };
  });

  let trials = [];
  trials.push(...loadingSequence(experiment_assets));
  trials.push(...instructionSequence);
  trials.push(...inference_trials);
  trials.push(...exitSurveySequence);

  jsPsych.run(trials);
}
