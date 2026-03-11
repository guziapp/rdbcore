import localUnitTest from './LocalUnit.test';
import rdbcoreUnitTest from './RdbUnit.test'

export default function testsuite() {
  localUnitTest();
  rdbcoreUnitTest();
}