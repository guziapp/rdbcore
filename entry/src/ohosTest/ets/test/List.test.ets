/**
 * 测试套件入口
 * 
 * 导入所有测试模块
 */
import abilityTest from './Ability.test'
import entityTest from './Entity.test'
import databaseManagerTest from './DatabaseManager.test'
import userServiceTest from './UserService.test'
import productServiceTest from './ProductService.test'
import orderServiceTest from './OrderService.test'
import viewModelTest from './ViewModel.test'

export default function testsuite(): void {
  // 原有测试
  abilityTest()
  
  // 新增测试
  entityTest()
  databaseManagerTest()
  userServiceTest()
  productServiceTest()
  orderServiceTest()
  viewModelTest()
}
