
-- luarocks install busted
-- luarocks install lua-requests

local requests = require 'requests'
local socket = require 'socket'
local json = require 'cjson'
local erorr_table = {
  [100] = 'نوع درخواست باید POST باشد',
  [101] = 'api_key ارسال نشده است یا صحیح نیست',
  [102] = 'مبلغ ارسال نشده است یا کمتر از 1000 ریال است',
  [103] = 'آدرس بازگشت ارسال نشده است',
  [301] = 'خطایی در برقراری با سرور بانک رخ داده است',
  [200] = 'شناسه پرداخت صحیح نیست',
  [201] = 'پرداخت انجام نشده است',
  [202] = 'پرداخت کنسل شده است یا خطایی در مراحل پرداخت رخ داده است',
}

local function GetPaymentID(api_key, amount, return_url)
  local data = json.encode({
    api_key = api_key,
    amount = amount,
    return_url = socket.url.escape(return_url)
  })
  local data = requests.post{'https://poolam.ir/invoice/request', data = data}
  if data.status_code ~= 200 then
    return {ok = false , text = 'خطا در اتصال به درگاه پرداخت'}
  end
  local output = json.decode(data.text)
  if output.status == 0 then
    return {ok = false , text = erorr_table[output.errorCode]}
  end
  if not output.invoice_key then
    return {ok = false, text = 'خطای غیر منتظره از سمت درگاه'}
  end
  return {ok = true , invoice_key = output.invoice_key, PaymentLink = 'https://poolam.ir/invoice/pay/'..output.invoice_key}
end

local function CheckPayment(api_key, invoice_key)
  local data = json.encode({
    api_key = api_key
  })
  local url = 'https://poolam.ir/invoice/check/'..invoice_key
  local data = requests.post{url, data = data}
  if data.status_code ~= 200 then
    return {ok = false , text = 'وضعیت تراکنش نامشخص'}
  end
  local output = json.decode(data.text)
  if output.status == 0 then
    return {ok = false , text = erorr_table[output.errorCode]}
  end
  if not output.bank_code then
    return {ok = false, text = 'خطای غیر منتظره از سمت درگاه'}
  end
  return {ok = true, amount = output.amount, bank_code = output.bank_code}
end
