import { render, screen } from '@testing-library/react'
import { userEvent } from '@testing-library/user-event'
import Template from 'app/template'
import { http, HttpResponse } from 'msw'
import { setupServer } from 'msw/node'

// useHistory()のpushメソッドをモックする
const mockHistoryPush = jest.fn()
jest.mock('react-router-dom', () => ({
    useHistory: () => ({
        push: mockHistoryPush,
    })
}))


// MSWは、React公式のモック用ライブラリ
// 最新バージョンへの変更は以下を参照
// https://qiita.com/KokiSakano/items/62180f334a6137d429b5
// 今回はAPIをjsonplaceholderのものを使用。
const handlers = [
    http.get('https://jsonplaceholder.typicode.com/users/1', ({ request, params, cookies }) => {
        return HttpResponse.json({ username:'Test User' })
    }),
    http.get('/https://jsonplaceholder.typicode.com/todos/1', ({ request, params, cookies }) => {
      return HttpResponse.json([
        {
           "userId": 1,
           "id": 1,
           "title": "delectus aut autem",
           "completed": false
        },
        {
           "userId": 1,
           "id": 2,
           "title": "quis ut nam facilis et officia qui",
           "completed": false
        },
      ])
    }),
]

const server = setupServer(...handlers)

// 以下はMSWを使用する際に毎回記載が必要なおまじないと思うと良い
// このスクリプトが開始時に実行
beforeAll(() => server.listen())

// 各テストを実行する度に実行される
afterEach(() => server.resetHandlers())

// このスクリプト終了時に実行
afterAll(() => server.close())

// describe関数は各テストのグルーピングする関数。
describe('Mocking API', () => {
    // testは各テストを行う関数
    test('debug', () => {
        screen.debug()
    })
    // itは各テストを行う関数
    // testとの違いは、testは純粋にテスト内容を表記し、itは英文としてitに続くようにテスト内容を記述する。
    // 実行内容自体は同じ。
    it('display fetched data and button disable [Fetch success]', async () => {
        render(<Template />)
        userEvent.click(screen.getByRole('button'))
        expect(await screen.findByRole('heading')).toHaveTextContent('Test User')
        expect(screen.getByRole('button')).toHaveAttribute('disable')
    }),
    it('display fetched data and button disable [Fetch success]', async () => {
        server.use(
            http.get(
                'https://jsonplaceholder.typicode.com/users/1',
                ({ request, params, cookies }) => {
                return HttpResponse.json({ username:'Test User' })
            }),
        )
        render(<Template />)
        userEvent.click(screen.getByRole('button'))
        expect(await screen.findByRole('error')).toHaveTextContent('Fetching Failed !')
        expect(await screen.queryByRole('heading')).toBeNull()
        expect(screen.getByRole('button')).not.toHaveAttribute('disable')
    })
})