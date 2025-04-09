<template>
  <div class="container">
    <h1>🛸 小胡桃服务器导航</h1>

    <!-- 新增按钮 -->
    <div class="action-bar">
      <button class="add-btn" @click="showAddModal = true">
        <svg class="icon" viewBox="0 0 24 24">
          <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/>
        </svg>
        新增链接
      </button>
    </div>

    <!-- 新增模态框 -->
    <div v-if="showAddModal" class="modal">
      <div class="modal-content">
        <h3>新增链接</h3>
        <form @submit.prevent="addCard">
          <div class="form-group">
            <label>标题</label>
            <input v-model="newTitle" required>
          </div>
          <div class="form-group">
            <label>链接</label>
            <input v-model="newLink" required>
          </div>
          <div class="form-actions">
            <button type="button" @click="showAddModal = false">取消</button>
            <button type="submit">确认添加</button>
          </div>
        </form>
      </div>
    </div>

    <!-- 编辑模态框 -->
    <div v-if="showEditModal" class="modal">
      <div class="modal-content">
        <h3>编辑链接</h3>
        <form @submit.prevent="updateCard">
          <div class="form-group">
            <label>标题</label>
            <input v-model="editTitle" required>
          </div>
          <div class="form-group">
            <label>链接</label>
            <input v-model="editLink" required>
          </div>
          <div class="form-actions">
            <button type="button" @click="cancelEdit">取消</button>
            <button type="submit">保存修改</button>
          </div>
        </form>
      </div>
    </div>

    <!-- 骨架屏加载状态 -->
    <div v-if="loading" class="grid-container">
      <div
        v-for="n in 4"
        :key="n"
        class="skeleton-card"
      ></div>
    </div>

    <!-- 错误状态 -->
    <div v-if="error" class="error">
      <p>加载失败，请稍后重试</p>
      <button @click="retry">重新加载</button>
    </div>

    <!-- 正常内容 -->
    <div class="grid-container" v-if="!loading && !error">
      <article
        class="card"
        v-for="(item, index) in cards"
        :key="item.id"
      >
        <a :href="item.link" class="card-content">
          <span class="card-number">{{ padNumber(index + 1) }}</span>
          <span class="card-title">{{ item.title }}</span>
        </a>

        <!-- 下拉菜单 -->
        <div class="dropdown">
          <button class="dropdown-toggle" @click.stop="toggleDropdown(item.id)">
            <svg class="icon" viewBox="0 0 24 24">
              <path d="M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"/>
            </svg>
          </button>
          <transition name="slide-fade">
            <div v-if="activeDropdown === item.id" class="dropdown-menu">
              <button @click.stop="startEdit(item)">编辑</button>
              <button @click.stop="deleteCard(item.id)">删除</button>
            </div>
          </transition>
        </div>
      </article>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

interface CardItem {
  id: number
  title: string
  link: string
}

const cards = ref<CardItem[]>([])
const loading = ref(true)
const error = ref(false)
const newTitle = ref('')
const newLink = ref('')
const showAddModal = ref(false)
const showEditModal = ref(false)
const editId = ref(0)
const editTitle = ref('')
const editLink = ref('')
const activeDropdown = ref<number | null>(null)

const fetchData = async (): Promise<void> => {
  try {
    const response = await axios.get<CardItem[]>('http://nas.xiaohutao.xyz:9008/api/selectHtml')
    if (Array.isArray(response.data)) {
      cards.value = response.data.map(item => ({
        ...item,
        id: Number(item.id)
      }))
    } else {
      console.error('响应数据格式不正确')
      error.value = true
    }
  } catch (err) {
    console.error('数据加载失败:', err)
    error.value = true
  } finally {
    loading.value = false
  }
}

const padNumber = (num: number): string => {
  return num.toString().padStart(2, '0')
}

const retry = (): void => {
  error.value = false
  loading.value = true
  fetchData()
}

const addCard = async (): Promise<void> => {
  try {
    await axios.post('http://nas.xiaohutao.xyz:9008/api/addHtml', {
      title: newTitle.value,
      link: newLink.value
    })
    newTitle.value = ''
    newLink.value = ''
    showAddModal.value = false
    fetchData()
  } catch (err) {
    console.error('新增失败:', err)
  }
}

const startEdit = (item: CardItem): void => {
  showEditModal.value = true
  activeDropdown.value = null
  editId.value = item.id
  editTitle.value = item.title
  editLink.value = item.link
}

const cancelEdit = (): void => {
  showEditModal.value = false
  editId.value = 0
  editTitle.value = ''
  editLink.value = ''
}

const updateCard = async (): Promise<void> => {
  try {
    await axios.put('http://nas.xiaohutao.xyz:9008/api/updateHtml', {
      id: editId.value,
      title: editTitle.value,
      link: editLink.value
    })
    cancelEdit()
    fetchData()
  } catch (err) {
    console.error('更新失败:', err)
  }
}

const deleteCard = async (id: number): Promise<void> => {
  try {
    await axios.delete(`http://nas.xiaohutao.xyz:9008/api/deleteHtml/${id}`)
    fetchData()
  } catch (err) {
    console.error('删除失败:', err)
  }
}

const toggleDropdown = (id: number) => {
  activeDropdown.value = activeDropdown.value === id ? null : id
}

// 点击外部关闭下拉菜单-
document.addEventListener('click', (e) => {
  if (!(e.target as HTMLElement).closest('.dropdown')) {
    activeDropdown.value = null
  }
})

onMounted(fetchData)
</script>

<style scoped>
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem 1rem;
}

h1 {
  text-align: center;
  font-size: 2.5rem;
  color: #ff4757;
  margin-bottom: 2rem;
  text-shadow: 1px 1px 2px rgba(0,0,0,0.1);
  animation: fadeInDown 0.8s ease;
}

.grid-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.5rem;
  padding: 1rem;
}

.card {
  background: rgba(255, 255, 255, 0.95);
  border-radius: 12px;
  padding: 1.5rem;
  transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
  position: relative;
}

.card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 15px rgba(255, 71, 87, 0.2);
}

.card-content {
  display: block;
  text-decoration: none;
  color: inherit;
}

.card-number {
  font-size: 1.2rem;
  color: #ff6b6b;
  font-weight: 700;
  opacity: 0.8;
}

.card-title {
  display: block;
  font-size: 1.4rem;
  font-weight: 600;
  color: #333;
  margin-top: 0.5rem;
  transition: color 0.3s ease;
}

.card:hover .card-title {
  color: #ff4757;
}

.action-bar {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 2rem;
}

.add-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 24px;
  background: #ff4757;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.add-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(255, 71, 87, 0.3);
}

.icon {
  width: 20px;
  height: 20px;
  fill: currentColor;
}

.dropdown {
  position: absolute;
  top: 1rem;
  right: 1rem;
}

.dropdown-toggle {
  background: none;
  border: none;
  padding: 4px;
  cursor: pointer;
  opacity: 0.6;
  transition: all 0.3s;
}

.dropdown-toggle:hover {
  opacity: 1;
  transform: rotate(90deg);
}

.dropdown-menu {
  position: absolute;
  right: 0;
  top: 100%;
  background: white;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  min-width: 120px;
  overflow: hidden;
  z-index: 10;
}

.dropdown-menu button {
  width: 100%;
  padding: 10px 16px;
  text-align: left;
  background: none;
  border: none;
  color: #666;
  cursor: pointer;
  transition: all 0.2s;
}

.dropdown-menu button:hover {
  background: #fff5f5;
  color: #ff4757;
}

.modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  max-width: 500px;
  width: 90%;
  animation: modalIn 0.3s ease;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #666;
}

.form-group input {
  width: 100%;
  padding: 10px;
  border: 2px solid #eee;
  border-radius: 8px;
  transition: border-color 0.3s;
}

.form-group input:focus {
  border-color: #ff6b6b;
  outline: none;
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 2rem;
}

.form-actions button {
  padding: 10px 20px;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.form-actions button[type="button"] {
  background: #eee;
  color: #666;
}

.form-actions button[type="submit"] {
  background: #ff4757;
  color: white;
}

.skeleton-card {
  height: 120px;
  background: #f0f0f0;
  border-radius: 12px;
  background-image: linear-gradient(
    90deg,
    rgba(255,255,255,0) 0%,
    rgba(255,255,255,0.5) 50%,
    rgba(255,255,255,0) 100%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

.error {
  text-align: center;
  font-size: 1.2rem;
  color: #ff4757;
  padding: 2rem;
}

.error button {
  margin-top: 1rem;
  padding: 0.5rem 1.5rem;
  background: #ff4757;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

@keyframes fadeInDown {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes modalIn {
  from {
    transform: translateY(-20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

@keyframes shimmer {
  from { background-position: -200% 0; }
  to { background-position: 200% 0; }
}

.slide-fade-enter-active {
  transition: all 0.2s ease-out;
}

.slide-fade-leave-active {
  transition: all 0.15s ease-in;
}

.slide-fade-enter-from,
.slide-fade-leave-to {
  transform: translateY(-10px);
  opacity: 0;
}

@media (max-width: 768px) {
  .container {
    padding: 1rem;
  }

  h1 {
    font-size: 2rem;
  }

  .grid-container {
    grid-template-columns: 1fr;
  }

  .modal-content {
    padding: 1.5rem;
  }
}
</style>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Segoe UI', system-ui, sans-serif;
  line-height: 1.6;
  background: linear-gradient(135deg, #fff5f5 0%, #ffe3e3 100%);
  color: #4a4a4a;
  min-height: 100vh;
}
</style>
