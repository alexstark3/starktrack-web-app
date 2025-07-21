# DNS Setup Guide for Admin Subdomain

## 🌐 Subdomain Configuration: `admin.starktrack.ch`

### **Current Setup:**
- **Main App**: `starktrack.ch` (your custom domain)
- **Admin App**: `admin.starktrack.ch` (new subdomain)

### **Step 1: Firebase Hosting Setup**

First, we need to create a new Firebase hosting site for the admin subdomain:

```bash
# Create a new hosting site for admin
firebase hosting:sites:create admin-starktracklog

# This will give you a URL like: admin-starktracklog.web.app
```

### **Step 2: DNS Configuration**

You need to add a CNAME record in your domain registrar's DNS settings:

#### **CNAME Record:**
```
Type:    CNAME
Name:    admin
Value:   admin-starktracklog.web.app
TTL:     3600 (or default)
```

#### **Where to Add This:**
1. **Go to your domain registrar** (where you bought starktrack.ch)
2. **Find DNS Management** or **DNS Settings**
3. **Add the CNAME record** as shown above
4. **Save the changes**

### **Step 3: Firebase Domain Verification**

After adding the DNS record, you need to verify the domain in Firebase:

```bash
# Add the custom domain to Firebase
firebase hosting:sites:add admin-starktracklog admin.starktrack.ch

# This will give you verification instructions
```

### **Step 4: SSL Certificate**

Firebase will automatically provision an SSL certificate for your subdomain.

### **Step 5: Test the Setup**

Once DNS propagates (can take up to 24 hours):

1. **Test admin access**: `https://admin.starktrack.ch`
2. **Test main app**: `https://starktrack.ch`
3. **Verify separation**: Company users should be redirected from admin subdomain

## 🔧 **Alternative Setup Methods**

### **Method 1: Firebase Console**
1. Go to Firebase Console → Hosting
2. Click "Add custom domain"
3. Enter `admin.starktrack.ch`
4. Follow the verification steps

### **Method 2: Firebase CLI**
```bash
# Add custom domain
firebase hosting:sites:add admin-starktracklog admin.starktrack.ch

# Verify domain
firebase hosting:sites:get admin-starktracklog
```

## 📋 **Verification Checklist**

- [ ] CNAME record added to DNS
- [ ] Domain verified in Firebase
- [ ] SSL certificate provisioned
- [ ] Admin web app deployed
- [ ] Admin users created
- [ ] Access tested from both domains

## 🚨 **Common Issues**

### **DNS Not Propagated**
- **Symptom**: `admin.starktrack.ch` doesn't work
- **Solution**: Wait up to 24 hours for DNS propagation
- **Check**: Use `nslookup admin.starktrack.ch` to verify

### **SSL Certificate Issues**
- **Symptom**: HTTPS shows certificate errors
- **Solution**: Wait for Firebase to provision SSL (can take 1-2 hours)
- **Check**: Verify domain in Firebase Console

### **Firebase Hosting Not Found**
- **Symptom**: 404 errors on admin subdomain
- **Solution**: Ensure admin web app is deployed to correct hosting site
- **Check**: Verify deployment with `firebase hosting:sites:list`

## 🔒 **Security Considerations**

### **Domain Separation**
- ✅ Admin and company users on different subdomains
- ✅ No cross-access between admin and company data
- ✅ Separate authentication systems

### **Access Control**
- ✅ Only admin users can access `admin.starktrack.ch`
- ✅ Company users redirected to main app
- ✅ Admin users stored in separate collection

### **SSL/TLS**
- ✅ Automatic SSL certificates for both domains
- ✅ Secure communication for all admin functions
- ✅ HTTPS enforcement

## 📞 **Support**

If you encounter issues:

1. **Check DNS propagation**: `nslookup admin.starktrack.ch`
2. **Verify Firebase hosting**: `firebase hosting:sites:list`
3. **Check deployment**: `firebase hosting:sites:get admin-starktracklog`
4. **Review logs**: Firebase Console → Hosting → Logs

## 🎯 **Expected Result**

After setup, you should have:

```
Main App:     https://starktrack.ch
             ├── Company users login
             ├── Company dashboard
             └── Company data access

Admin App:    https://admin.starktrack.ch
             ├── Admin users login
             ├── Admin dashboard
             ├── Migration tool
             └── System management
```

Complete separation with professional domain structure! 🚀 