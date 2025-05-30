import { loadingSequence } from "./loading-sequence.mjs";
import { instructionsLoop } from "./instructions.mjs";
import { exitSurveySequence } from "./exit-sequence.mjs";
import { getJsPsych } from "./jspsych-singleton.mjs";

export function setupGame() {
  const jsPsych = getJsPsych();

  const experiment_assets = [
    "assets/1_cook.png",
    "assets/2_cooks.png",
    "assets/onion_lettuce.png",
    "assets/tomato_lettuce.png",
  ];

  const trial_stims = [
    "assets/stims/1agent-onion.png",
    "assets/stims/1agent-tomato.png",
    "assets/stims/1agent-either_recipe.png",
    "assets/stims/2agent-onion.png",
    "assets/stims/2agent-tomato.png",
    "assets/stims/2agent-either_recipe.png",
    "assets/stims/either_agents-onion.png",
    "assets/stims/either_agents-tomato.png",
    "assets/stims/either_agents-either_recipe.png",
  ];

  // trial objects

  const inference_trials = _.map(_.shuffle(trial_stims), (stim, i) => {
    return {
      type: jsPsychSurveySlider,
      // trial stimuli image
      preamble: `<img src="${stim}" style="height: 450px;">`,
      questions: [
        {
          prompt: "How many cooks was this kitchen made for?",
          name: "intent_agents",
          min_label: "<img src='assets/1_cook.png' style='height: 60px;'>",
          max_label: "<img src='assets/2_cooks.png' style='height: 60px;'>",
        },
        {
          prompt: "What dish was this kitchen made for?",
          name: "intent_recipe",
          min_label:
            "<img src='assets/tomato_lettuce.png' style='height: 60px;'>",
          max_label:
            "<img src='assets/onion_lettuce.png' style='height: 60px;'>",
        },
      ],
      require_movement: true,
      slider_width: 800,
    };
  });

  let trials = [];
  trials.push(...loadingSequence([...experiment_assets, ...trial_stims]));
  trials.push(instructionsLoop);
  trials.push(...inference_trials);
  trials.push(...exitSurveySequence);

  jsPsych.run(trials);
}
