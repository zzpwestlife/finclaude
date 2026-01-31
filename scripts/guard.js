#!/usr/bin/env node
/**
 * FinClaude 金融级质量门禁
 * 提交前强制检查脚本
 * 
 * 检查项：
 * 1. 测试覆盖率 ≥ 80%
 * 2. 安全审计 - 无高危漏洞
 * 3. 代码简化
 * 4. 复杂度检查（Cyclomatic Complexity ≤ 10）
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// 颜色定义
const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const BLUE = '\x1b[34m';
const NC = '\x1b[0m';

// 配置（可从环境变量读取）
const COVERAGE_THRESHOLD = parseInt(process.env.COVERAGE_THRESHOLD || '80', 10);
const COMPLEXITY_THRESHOLD = parseInt(process.env.COMPLEXITY_THRESHOLD || '10', 10);

// 日志函数
function logInfo(msg) {
  console.log(`${BLUE}[FINCLAUDE]${NC} ${msg}`);
}

function logSuccess(msg) {
  console.log(`${GREEN}[PASS]${NC} ${msg}`);
}

function logError(msg) {
  console.log(`${RED}[FAIL]${NC} ${msg}`);
}

function logWarning(msg) {
  console.log(`${YELLOW}[WARN]${NC} ${msg}`);
}

// 检查测试覆盖率
function checkTestCoverage() {
  logInfo(`检查测试覆盖率 (要求 ≥ ${COVERAGE_THRESHOLD}%)...`);
  
  try {
    // 检查是否有测试脚本
    const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf-8'));
    if (!packageJson.scripts || !packageJson.scripts.test) {
      logWarning('未找到 test 脚本，跳过测试检查');
      return true;
    }
    
    // 运行测试并获取覆盖率
    const output = execSync(
      'npm test -- --coverage --coverageReporters=text-summary 2>&1',
      {
        encoding: 'utf-8',
        stdio: ['pipe', 'pipe', 'pipe'],
        maxBuffer: 10 * 1024 * 1024 // 10MB
      }
    );
    
    // 解析覆盖率
    const linesMatch = output.match(/Lines\s*:\s*(\d+\.?\d*)%/);
    const statementsMatch = output.match(/Statements\s*:\s*(\d+\.?\d*)%/);
    const functionsMatch = output.match(/Functions\s*:\s*(\d+\.?\d*)%/);
    const branchesMatch = output.match(/Branches\s*:\s*(\d+\.?\d*)%/);
    
    const coverage = linesMatch ? parseFloat(linesMatch[1]) : 0;
    
    // 打印详细覆盖率
    console.log('');
    console.log('  覆盖率详情:');
    if (statementsMatch) console.log(`    Statements: ${statementsMatch[1]}%`);
    if (branchesMatch) console.log(`    Branches:   ${branchesMatch[1]}%`);
    if (functionsMatch) console.log(`    Functions:  ${functionsMatch[1]}%`);
    if (linesMatch) console.log(`    Lines:      ${linesMatch[1]}%`);
    console.log('');
    
    if (coverage >= COVERAGE_THRESHOLD) {
      logSuccess(`测试覆盖率: ${coverage}% (≥ ${COVERAGE_THRESHOLD}%)`);
      return true;
    } else {
      logError(`测试覆盖率: ${coverage}% (要求 ≥ ${COVERAGE_THRESHOLD}%)`);
      console.log('');
      console.log('  建议:');
      console.log('    1. 补充边界 case 测试');
      console.log('    2. 检查未覆盖的分支');
      console.log('    3. 运行 npm test -- --coverage 查看详细报告');
      return false;
    }
  } catch (e) {
    logError('测试执行失败');
    if (e.stdout) console.log(e.stdout);
    if (e.stderr) console.log(e.stderr);
    return false;
  }
}

// 检查安全审计
function checkSecurityAudit() {
  logInfo('检查安全漏洞...');
  
  try {
    execSync('npm audit --audit-level=high', { stdio: 'pipe' });
    logSuccess('安全审计通过');
    return true;
  } catch (e) {
    logError('发现高危安全漏洞');
    console.log('');
    console.log('  修复命令:');
    console.log('    npm audit fix          # 自动修复');
    console.log('    npm audit fix --force  # 强制修复（可能破坏依赖）');
    console.log('    npm audit              # 查看详细信息');
    return false;
  }
}

// 运行代码简化
function runCodeSimplifier() {
  logInfo('运行代码简化...');
  
  try {
    // 检查 code-simplifier 是否安装
    execSync('npx code-simplifier --help', { stdio: 'pipe' });
    
    // 运行简化
    execSync('npx code-simplifier', { stdio: 'inherit' });
    logSuccess('代码简化完成');
    return true;
  } catch (e) {
    logWarning('code-simplifier 未安装或运行失败，跳过');
    console.log('  安装命令: /plugin install code-simplifier');
    return true; // 非阻塞
  }
}

// 检查代码复杂度
function checkComplexity() {
  logInfo(`检查代码复杂度 (要求 ≤ ${COMPLEXITY_THRESHOLD})...`);
  
  try {
    // 检查是否有 complexity 检查工具
    execSync('which complexity-report || npm list -g complexity-report', { stdio: 'pipe' });
    
    // 运行复杂度检查
    const output = execSync('complexity-report src/', { encoding: 'utf-8', stdio: 'pipe' });
    const complexityMatch = output.match(/average complexity:\s*(\d+\.?\d*)/i);
    
    if (complexityMatch) {
      const avgComplexity = parseFloat(complexityMatch[1]);
      if (avgComplexity <= COMPLEXITY_THRESHOLD) {
        logSuccess(`平均复杂度: ${avgComplexity} (≤ ${COMPLEXITY_THRESHOLD})`);
        return true;
      } else {
        logWarning(`平均复杂度: ${avgComplexity} (建议 ≤ ${COMPLEXITY_THRESHOLD})`);
        return true; // 警告但不阻塞
      }
    }
    
    return true;
  } catch (e) {
    logWarning('未安装复杂度检查工具，跳过');
    return true; // 非阻塞
  }
}

// 主流程
console.log('');
console.log('╔════════════════════════════════════════════════════════════╗');
console.log('║          FinClaude 金融级质量门禁                          ║');
console.log('╚════════════════════════════════════════════════════════════╝');
console.log('');

let passed = true;

// 检查是否在项目根目录
if (!fs.existsSync('package.json')) {
  logWarning('未找到 package.json，跳过部分检查');
}

// 执行检查
passed = checkTestCoverage() && passed;
passed = checkSecurityAudit() && passed;
passed = runCodeSimplifier() && passed;
checkComplexity(); // 非阻塞

// 输出结果
console.log('');
console.log('╔════════════════════════════════════════════════════════════╗');
if (passed) {
  console.log('║  ' + GREEN + '✅ 金融级质量门禁通过' + ' '.repeat(43 - 24) + NC + '║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('');
  process.exit(0);
} else {
  console.log('║  ' + RED + '❌ 质量门禁检查失败' + ' '.repeat(43 - 22) + NC + '║');
  console.log('║  请修复上述问题后重试' + ' '.repeat(43 - 22) + '║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log('');
  console.log('  强制提交（不推荐）:');
  console.log('    git commit --no-verify -m "your message"');
  console.log('');
  process.exit(1);
}
