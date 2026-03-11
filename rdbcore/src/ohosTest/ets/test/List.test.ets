import batchTransactionScenarioTest from './scenario/BatchTransactionScenario.test'
import deleteRestoreScenarioTest from './scenario/DeleteRestoreScenario.test'
import detailPatchScenarioTest from './scenario/DetailPatchScenario.test'
import listSearchScenarioTest from './scenario/ListSearchScenario.test'
import profileFlowScenarioTest from './scenario/ProfileFlowScenario.test'

export default function testsuite() {
  batchTransactionScenarioTest()
  deleteRestoreScenarioTest()
  detailPatchScenarioTest()
  listSearchScenarioTest()
  profileFlowScenarioTest()
}