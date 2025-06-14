import { settings } from "../config.mjs";

const landingPage = {
  type: jsPsychInstructions,
  pages: [
    `<p> Hello! Thank you for participating in this research.</p> \
    <p> We expect the study to last about ${settings.experiment_params.time_estimate} minutes, including the time it takes to read these instructions.</p> \
    <i><p> Note: We recommend completing the study in Chrome. It has not been tested in other browsers.</p></i>`,
  ],
  show_clickable_nav: true,
  allow_keys: true,
  allow_backward: true,
};

const preload = (assets) => {
  return {
    type: jsPsychPreload,
    images: assets,
  };
};

const browserCheck = {
  type: jsPsychBrowserCheck,
};

const consent = {
  type: jsPsychHtmlButtonResponse,
  stimulus:
    "<p><b> Consent Form </b></p>" +
    '<div style="text-align: left; background-color: lightblue; overflow: auto; height: 500px;' +
    ' padding: 20px; max-width: 900px;">' +
    "<p><b>Description:</b> Welcome! You are invited to participate" +
    " in a research study in psychology. You will be asked to" +
    " perform various tasks on a computer which may include looking" +
    " at images or videos, reading text, and/or playing games." +
    " You may be asked a number of different questions about making" +
    " judgments and interpreting people's actions. All information" +
    " collected will remain confidential. </p>" +
    " <p> <b>Risks and benefits:</b> Risks involved in this study" +
    " are the same as those normally associated with using a" +
    " computer. If you have any pre-existing conditions that" +
    " might make reading and completing a computer-based survey" +
    " strenuous for you, you should probably elect not to participate" +
    " in this study. If at any time during the study you feel unable" +
    " to participate because you are experiencing strain, you may" +
    " end your participation without penalty. We cannot and do not" +
    " promise that you will receive any benefits from this study." +
    " Your decision about whether or not to participate in this" +
    " study will not affect your employment, medical care, or" +
    " grades in school. </p>" +
    "<p><b>Time involvement:</b> Your participation in this" +
    " experiment will take " +
    settings.experiment_params.time_estimate +
    " minutes. </p>" +
    "<p><b> Payment:</b> If recruitment materials indicate payment" +
    " (e.g., Prolific or other recruitment), then you" +
    " will receive compensation as indicated. </p>" +
    "<p><b>Subject's rights:</b> If you have read this notice and" +
    " decided to participate in this study, please understand that" +
    " your participation is voluntary and that you have the right to" +
    " withdraw your consent or discontinue participation at any" +
    " time without penalty or loss of benefits to which you are" +
    " otherwise entitled. You have the right to refuse to answer" +
    " particular questions. Your individual privacy will be" +
    " maintained in all published and written data resulting from" +
    " the study. </p>" +
    "<p><b>Contact information:</b> If you have any questions," +
    " concerns, or complaints about this research study, its" +
    " procedures, or risks and benefits, you can contact" +
    " Justin Yang" +
    " (justin.yang@stanford.edu). </p>" +
    // " procedures, or risks and benefits, you can contact the" +
    // " Protocol Director, Professor Tobias Gerstenberg" +
    // " (gerstenberg@stanford.edu). </p>" +
    " <p> By clicking the button below, you acknowledge that" +
    " you have read the above information, that you are 18 years" +
    " of age or older, and that you give your consent to participate" +
    " in our internet-based study and for us to analyze the" +
    " resulting data. </p>" +
    "</div>" +
    "<p> Do you agree with the terms of the experiment as explained" +
    " above? </p>",
  choices: ["I agree"],
  margin_vertical: "30px",
};

export const loadingSequence = (assets) => {
  return [landingPage, consent, browserCheck, preload(assets)];
};
