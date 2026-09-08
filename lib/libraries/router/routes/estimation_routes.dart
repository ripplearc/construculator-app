const String estimationBaseRoute = '/estimation';
const String estimationDetailsRoute = '/details/:estimationId';
const String fullEstimationDetailsRoute = '$estimationBaseRoute/details';

const String addMaterialCostRoute = '/cost-item/material/:estimationId';
const String addLabourCostRoute = '/cost-item/labour/:estimationId';
const String addEquipmentCostRoute = '/cost-item/equipment/:estimationId';

const String fullAddMaterialCostRoute = '$estimationBaseRoute/cost-item/material';
const String fullAddLabourCostRoute = '$estimationBaseRoute/cost-item/labour';
const String fullAddEquipmentCostRoute = '$estimationBaseRoute/cost-item/equipment';
